import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

bool isBase64(String str) {
  try {
    base64Decode(str);
    return true;
  } catch (_) {
    return false;
  }
}

String decryptAES(String encryptedText, String encryptionKey, IV iv) {
  // Decode base64 to raw bytes first so we can inspect length and provide
  // clearer error messages when decryption fails.
  List<int> bytes;
  try {
    bytes = base64Decode(encryptedText);
  } catch (e) {
    // Try a hex decode fallback if base64 fails (sometimes data arrives hex-encoded)
    final hexOnly = encryptedText.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    if (hexOnly.length % 2 == 0 && hexOnly.isNotEmpty) {
      try {
        bytes = List<int>.generate(hexOnly.length ~/ 2,
            (i) => int.parse(hexOnly.substring(i * 2, i * 2 + 2), radix: 16));
      } catch (_) {
        throw ArgumentError('Base64 decode failed: ${e.toString()}');
      }
    } else {
      throw ArgumentError('Base64 decode failed: ${e.toString()}');
    }
  }

  try {
    final key = Key.fromUtf8(encryptionKey);
    // Use default padding behavior of the package (PKCS7 normally).
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = Encrypted(Uint8List.fromList(bytes));
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted;
  } catch (e) {
    final byteLen = bytes.length;
    print(
        'DEBUG: Primary decryption failed: ${e.toString()} (ciphertext bytes=${byteLen})');

    // Try fallback: if data contains IV prefixed (common pattern), use it
    try {
      if (bytes.length > 16) {
        final ivBytes = bytes.sublist(0, 16);
        final cipherBytes = bytes.sublist(16);
        print(
            'DEBUG: Trying prefixed-IV fallback (iv bytes=${ivBytes.length}, cipher bytes=${cipherBytes.length})');
        final altIv = IV(Uint8List.fromList(ivBytes));
        final altEncrypted = Encrypted(Uint8List.fromList(cipherBytes));
        final key2 = Key.fromUtf8(encryptionKey);
        final encrypter2 = Encrypter(AES(key2, mode: AESMode.cbc));
        final decrypted2 = encrypter2.decrypt(altEncrypted, iv: altIv);
        print('DEBUG: Prefixed-IV fallback succeeded');
        return decrypted2;
      }
    } catch (e2) {
      print('DEBUG: Prefixed-IV fallback failed: ${e2.toString()}');
    }

    // Try fallback: if data contains IV suffixed (less common)
    try {
      if (bytes.length > 16) {
        final cipherBytes = bytes.sublist(0, bytes.length - 16);
        final ivBytes = bytes.sublist(bytes.length - 16);
        print(
            'DEBUG: Trying suffixed-IV fallback (cipher bytes=${cipherBytes.length}, iv bytes=${ivBytes.length})');
        final altIv = IV(Uint8List.fromList(ivBytes));
        final altEncrypted = Encrypted(Uint8List.fromList(cipherBytes));
        final key3 = Key.fromUtf8(encryptionKey);
        final encrypter3 = Encrypter(AES(key3, mode: AESMode.cbc));
        final decrypted3 = encrypter3.decrypt(altEncrypted, iv: altIv);
        print('DEBUG: Suffixed-IV fallback succeeded');
        return decrypted3;
      }
    } catch (e3) {
      print('DEBUG: Suffixed-IV fallback failed: ${e3.toString()}');
    }

    // Final diagnostic details: provide hex previews
    String hexPreview(List<int> b) {
      final take = 32;
      final preview =
          b.take(take).map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      final tail = b.length > take
          ? b
              .skip(b.length - take)
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join()
          : '';
      return 'len=${b.length} head=${preview}${tail.isNotEmpty ? ' tail=' + tail : ''}';
    }

    final headTail = hexPreview(bytes);
    throw ArgumentError(
        'Decryption failed: ${e.toString()} (ciphertext bytes=${byteLen}). hex_preview: $headTail');
  }
}
