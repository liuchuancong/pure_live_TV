import 'dart:math';
import 'dart:typed_data';

/// Splits an FLV byte stream into complete tags.
///
/// The stream is framed by DataSize rather than by the trailing
/// PreviousTagSize, which several FLV producers write incorrectly. The FLV
/// header and its initial zero-size field are yielded unchanged.
class FlvTagFramer {
  final BytesBuilder _pending = BytesBuilder(copy: false);
  int _expected = 9;
  int _phase = 0;

  /// Bytes held back until the next complete tag arrives.
  int get pendingBytes => _pending.length;

  /// Feeds [source] and yields every complete record it completes.
  ///
  /// Throws [FormatException] when the stream is not FLV.
  Iterable<Uint8List> add(List<int> source) sync* {
    final bytes = source is Uint8List ? source : Uint8List.fromList(source);
    var offset = 0;
    while (offset < bytes.length) {
      final take = min(_expected - _pending.length, bytes.length - offset);
      _pending.add(Uint8List.sublistView(bytes, offset, offset + take));
      offset += take;
      if (_pending.length != _expected) continue;
      final packet = _pending.takeBytes();
      if (_phase == 0) {
        if (packet[0] != 0x46 || packet[1] != 0x4c || packet[2] != 0x56 || packet[3] != 1) {
          throw const FormatException('Invalid FLV header');
        }
        final headerSize = ByteData.sublistView(packet).getUint32(5);
        if (headerSize < 9 || headerSize > 65536) throw const FormatException('Invalid FLV header size');
        _expected = headerSize + 4;
        _pending.add(packet);
        _phase = 1;
      } else if (_phase == 1) {
        if (ByteData.sublistView(packet).getUint32(packet.length - 4) != 0) {
          throw const FormatException('Invalid FLV initial tag size');
        }
        _expected = 11;
        _phase = 2;
        yield packet;
      } else if (_phase == 2) {
        final dataSize = (packet[1] << 16) | (packet[2] << 8) | packet[3];
        _expected = 11 + dataSize + 4;
        _pending.add(packet);
        _phase = 3;
      } else {
        // PreviousTagSize is unreliable in some FLV producers FFmpeg accepts.
        // DataSize defines the boundary; the trailing field is preserved.
        _expected = 11;
        _phase = 2;
        yield packet;
      }
    }
  }
}
