import 'dart:typed_data';

/// Rewrites legacy "codec id 12" HEVC FLV video tags into Enhanced FLV.
///
/// Several CDNs extended classic FLV with HEVC as codec id 12 before Enhanced
/// RTMP existed. FFmpeg only learned that id in 8.0; the FFmpeg 7.1.3 inside
/// media_kit's bundled libmpv drops the stream and plays audio only. Enhanced
/// FLV (`hvc1` FourCC) is understood since FFmpeg 6.1, so only the tag header
/// changes: NAL payloads and the HEVCDecoderConfigurationRecord are copied.
class FlvLegacyHevcTagRewriter {
  static const int _legacyHevcCodecId = 12;
  static const List<int> _hvc1 = <int>[0x68, 0x76, 0x63, 0x31];

  int _rewrittenTags = 0;

  /// Number of tags converted so far, for diagnostics.
  int get rewrittenTags => _rewrittenTags;

  /// [tag] is one complete FLV tag including its trailing PreviousTagSize, as
  /// produced by [FlvTagFramer]. Anything else is returned unchanged.
  Uint8List rewrite(Uint8List tag) {
    if (tag.length < 11 + 5 + 4 || (tag[0] & 0x1f) != 9) return tag;
    final flags = tag[11];
    if ((flags & 0x80) != 0 || (flags & 0x0f) != _legacyHevcCodecId) return tag;
    final dataSize = (tag[1] << 16) | (tag[2] << 8) | tag[3];
    if (dataSize < 5 || 11 + dataSize + 4 != tag.length) return tag;
    final frameType = (flags >> 4) & 0x07;
    final packetType = tag[12];
    // Legacy: flags, AVCPacketType, CompositionTime(3), data.
    // Enhanced: flags|packetType, FourCC, [CompositionTime(3) for coded frames], data.
    final List<int> prefix;
    final int payloadStart;
    switch (packetType) {
      case 0: // Sequence header -> SequenceStart.
        prefix = <int>[0x80 | (frameType << 4), ..._hvc1];
        payloadStart = 16;
      case 1: // NALUs -> CodedFrames (keeps the composition time).
        prefix = <int>[0x80 | (frameType << 4) | 1, ..._hvc1, tag[13], tag[14], tag[15]];
        payloadStart = 16;
      case 2: // End of sequence -> SequenceEnd.
        prefix = <int>[0x80 | (frameType << 4) | 2, ..._hvc1];
        payloadStart = 11 + dataSize;
      default:
        return tag;
    }
    final payloadLength = 11 + dataSize - payloadStart;
    final newDataSize = prefix.length + payloadLength;
    if (newDataSize > 0xffffff) return tag;
    final out = Uint8List(11 + newDataSize + 4);
    out.setRange(0, 11, tag);
    out[1] = (newDataSize >> 16) & 0xff;
    out[2] = (newDataSize >> 8) & 0xff;
    out[3] = newDataSize & 0xff;
    out.setRange(11, 11 + prefix.length, prefix);
    out.setRange(11 + prefix.length, 11 + newDataSize, tag, payloadStart);
    ByteData.sublistView(out).setUint32(11 + newDataSize, 11 + newDataSize);
    _rewrittenTags++;
    return out;
  }
}
