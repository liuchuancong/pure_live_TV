import 'dart:typed_data';

/// Big-endian byte reader and writer.
///
/// Single implementation for every wire format in the app: the danmaku packet
/// builders on Bilibili and Douyu, and the TARS codec used by the YY and CC
/// integrations. Both need the same fixed-width primitives, so they share this
/// file instead of carrying private copies. Every width accepts an explicit
/// [Endian] and defaults to big, which is what all current callers want.
class BinaryWriter {
  List<int> buffer;
  int position = 0;
  BinaryWriter(this.buffer);
  int get length => buffer.length;

  void writeBytes(List<int> list) {
    buffer.addAll(list);
    position += list.length;
  }

  void writeInt(int value, int len, {Endian endian = Endian.big}) {
    var b = Uint8List(len).buffer;
    var bytes = ByteData.view(b);
    if (len == 1) {
      // Write a byte.
      bytes.setUint8(0, value.toUnsigned(8));
    }
    if (len == 2) {
      bytes.setInt16(0, value, endian);
    }
    if (len == 4) {
      bytes.setInt32(0, value, endian);
    }
    if (len == 8) {
      bytes.setInt64(0, value, endian);
    }

    buffer.addAll(bytes.buffer.asUint8List());
    position += len;
  }

  void writeDouble(double value, int len, {Endian endian = Endian.big}) {
    var b = Uint8List(len).buffer;
    var bytes = ByteData.view(b);

    if (len == 4) {
      bytes.setFloat32(0, value, endian);
    }
    if (len == 8) {
      bytes.setFloat64(0, value, endian);
    }

    buffer.addAll(bytes.buffer.asUint8List());
    position += len;
  }
}

class BinaryReader {
  Uint8List buffer;
  int position = 0;
  BinaryReader(this.buffer);
  int get length => buffer.length;

  /// Reads the next byte and advances the stream position by one.
  /// Returns the next byte, 0-255.
  int read() {
    var byte = buffer[position];
    position += 1;
    return byte;
  }

  /// Reads an integer of the given width and advances the position by that width.
  /// [len] width in bytes
  /// len 1, 2, 4 and 8 map to int8, int16, int32 and int64; Dart uses int for all.
  /// Returns the integer.
  int readInt(int len, {Endian endian = Endian.big}) {
    var result = 0;
    // if (len == 1) {
    //   result = buffer[position];
    //   position += len;
    //   return result;
    // }
    var bytes = Uint8List.fromList(buffer.getRange(position, position + len).toList());
    var byteBuffer = bytes.buffer;
    var data = ByteData.view(byteBuffer);
    if (len == 1) {
      result = data.getUint8(0);
    }
    if (len == 2) {
      result = data.getInt16(0, endian);
    }
    if (len == 4) {
      result = data.getInt32(0, endian);
    }
    if (len == 8) {
      result = data.getInt64(0, endian);
    }
    position += len;
    return result;
  }

  /// Reads a byte.
  /// int width 1
  int readByte({Endian endian = Endian.big}) {
    return readInt(1, endian: endian);
  }

  /// Reads a value.
  /// int width 2
  int readShort({Endian endian = Endian.big}) {
    return readInt(2, endian: endian);
  }

  /// Reads a byte.
  /// int width 4
  int readInt32({Endian endian = Endian.big}) {
    return readInt(4, endian: endian);
  }

  /// Reads a byte.
  /// int width 8
  int readLong({Endian endian = Endian.big}) {
    return readInt(8, endian: endian);
  }

  /// Reads a byte array of the given width and advances the position.
  /// [len] width in bytes
  /// Returns the byte array.
  Uint8List readBytes(int len) {
    var bytes = Uint8List.fromList(buffer.getRange(position, position + len).toList());
    position += len;
    return bytes;
  }

  /// Reads a float of the given width and advances the position.
  /// [len] width in bytes
  /// len 4 is a float and 8 a double; Dart uses double for both.
  /// Returns the value.
  double readFloat(int len, {Endian endian = Endian.big}) {
    var result = 0.0;
    var bytes = Uint8List.fromList(buffer.getRange(position, position + len).toList());
    var byteBuffer = bytes.buffer;
    var data = ByteData.view(byteBuffer);
    if (len == 4) {
      result = data.getFloat32(0, endian);
    }
    if (len == 8) {
      result = data.getFloat64(0, endian);
    }
    position += len;
    return result;
  }
}
