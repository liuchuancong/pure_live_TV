import 'dart:convert';
import 'dart:typed_data';

class BufferParser {
  late Uint8List buffer;
  int offset = 0;

  BufferParser(this.buffer);

  // Reads a 32-bit unsigned integer.
  int getUI32() {
    final value = ByteData.view(buffer.buffer).getUint32(offset, Endian.little);
    offset += 4;
    return value;
  }

  // Reads a 16-bit unsigned integer.
  int getUI16() {
    final value = ByteData.view(buffer.buffer).getUint16(offset, Endian.little);
    offset += 2;
    return value;
  }

  // Reads a UTF-8 string, length first and content after.
  String getUTF8() {
    final len = getUI16();
    final subBuffer = buffer.sublist(offset, offset + len);
    offset += len;
    return utf8.decode(subBuffer);
  }

  // Reads a String-to-String map.
  Map<String, String> getStrStrMap() {
    final map = <String, String>{};
    final len = getUI32();
    for (var i = 0; i < len; i++) {
      final key = getUTF8();
      final value = getUTF8();
      map[key] = value;
    }
    return map;
  }

  // Combines two halves into a 64-bit integer, matching JS addToUInt64.
  int addToUInt64(int high, int low) {
    return (high << 32) | (low & 0xFFFFFFFF);
  }
}
