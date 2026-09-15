import 'const.dart';
import 'dart:typed_data';
import 'uni_packet.dart';
import 'package:pure_live/shared/utils/log.dart';

class TarsUniPacket extends UniPacket {
  TarsUniPacket() {
    package.iVersion = Const.PACKET_TYPE_TUP3;
    package.cPacketType = Const.PACKET_TYPE_TARSNORMAL;
    package.iMessageType = 0;
    package.iTimeout = 0;
    package.sBuffer = Uint8List.fromList([0x0]);
    package.context = <String, String>{};
    package.status = <String, String>{};
  }

  /// Sets the protocol version.
  void setTarsVersion(int version) {
    setVersion(version);
  }

  /// Sets the call type.
  void setTarsPacketType(int packetType) {
    package.cPacketType = packetType;
  }

  /// Sets the message type.
  void setTarsMessageType(int messageType) {
    package.iMessageType = messageType;
  }

  /// Sets the timeout.
  void setTarsTimeout(int timeout) {
    package.iTimeout = timeout;
  }

  /// Sets the encoded request payload.
  void setTarsBuffer(Uint8List buffer) {
    package.sBuffer = buffer;
  }

  /// Sets the context.
  void setTarsContext(Map<String, String> context) {
    package.context = context;
  }

  /// Sets the status value of a special message.
  void setTarsStatus(Map<String, String> status) {
    package.status = status;
  }

  /// Returns the protocol version.
  int getTarsVersion() {
    return package.iVersion;
  }

  /// Returns the call type.
  int getTarsPacketType() {
    return package.cPacketType;
  }

  /// Returns the message type.
  int getTarsMessageType() {
    return package.iMessageType;
  }

  /// Returns the timeout.
  int getTarsTimeout() {
    return package.iTimeout;
  }

  /// Returns the encoded request payload.
  Uint8List? getTarsBuffer() {
    return package.sBuffer;
  }

  /// Returns the context.
  Map<String, String>? getTarsContext() {
    return package.context;
  }

  /// Returns the status value of a special message.
  Map<String, String>? getTarsStatus() {
    return package.status;
  }

  /// Returns the value the Tars call produced.
  int getTarsResultCode() {
    int result = 0;
    try {
      String? rcode = package.status?[Const.STATUS_RESULT_CODE];
      result = (rcode != null ? int.tryParse(rcode) : 0)!;
    } catch (e) {
      Log.d('getTarsResultCode exception: $e');
      return 0;
    }
    return result;
  }

  /// Returns the description the Tars call produced.
  String getTarsResultDesc() {
    String? rdesc = package.status?[Const.STATUS_RESULT_DESC];
    String result = rdesc ?? "";
    return result;
  }
}
