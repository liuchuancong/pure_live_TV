import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:pure_live/shared/tars/tup/const.dart';
import 'package:pure_live/shared/tars/tup/tup_response.dart';
import 'package:pure_live/shared/tars/tup/tars_uni_packet.dart';
import 'package:pure_live/shared/tars/codec/tars_input_stream.dart';
import 'package:pure_live/shared/tars/tup/tup_result_exception.dart';

// TUP request wrapper.
// Note: only PACKET_TYPE_TUP3 = 3 packets are supported.
class BaseTarsHttp {
  final String baseUrl;
  final String path;
  final String servantName;
  final Map<String, String> headers;

  var timeOut = 60000;
  var debugLog = false;
  late final Dio dio;
  final logger = Logger();

  BaseTarsHttp(
    this.baseUrl,
    this.servantName, {
    this.path = "",
    this.timeOut = 60000,
    this.debugLog = false,
    this.headers = const {},
  }) {
    dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: timeOut),
        baseUrl: baseUrl,
        responseType: ResponseType.bytes,
        headers: {HttpHeaders.contentTypeHeader: "application/x-wup", ...headers},
      ),
    );
    if (debugLog) {
      dio.interceptors.add(LogInterceptor(responseBody: false)); // request logging
    }
  }

  // Sends a request without returning the status code; a failing status throws
  // TupResultException.
  Future<RSP> tupRequest<REQ, RSP>(String methodName, REQ tReq, RSP tRsp) async {
    TupResponse<RSP> response = await tupRequestWithRspCode(methodName, tReq, tRsp);
    if (response.code == 0) {
      return response.response!;
    } else {
      logger.e("tupDecode decode error:${response.code}");
      throw TupResultException(response.code);
    }
  }

  // Sends a request and returns both the status code and the response.
  Future<TupResponse<RSP>> tupRequestWithRspCode<REQ, RSP>(String methodName, REQ tReq, RSP tRsp) async {
    final data = buildRequest(methodName, tReq);
    dio.options.headers[HttpHeaders.contentLengthHeader] = data.lengthInBytes;
    final result = await dio.post<List<int>>(path, data: Stream.fromIterable(data.map((e) => [e])));
    final value = result.data;
    return tupResponseDecode(methodName, value!, tRsp);
  }

  // Sends a request with no response body and returns the status code.
  Future<TupResponse<void>> tupRequestWithRspCodeNoRsp<REQ>(String methodName, REQ tReq) async {
    final data = buildRequest(methodName, tReq);
    dio.options.headers[HttpHeaders.contentLengthHeader] = data.lengthInBytes;
    logger.d("send tupRequestNoRsp, methodName:$methodName");
    final result = await dio.post<List<int>>(path, data: Stream.fromIterable(data.map((e) => [e])));
    final value = result.data;
    return tupEmptyResponseDecode(methodName, value!);
  }

  // Sends a request with no response body and no status code; a failing status
  // throws TupResultException.
  Future<void> tupRequestNoRsp<REQ>(String methodName, REQ tReq) async {
    TupResponse<void> response = await tupRequestWithRspCodeNoRsp(methodName, tReq);
    if (response.code == 0) {
      return;
    } else {
      logger.e("tupDecode decode error:${response.code}");
      throw TupResultException(response.code);
    }
  }

  // Encode the packet.
  Uint8List buildRequest<REQ>(String methodName, REQ tReq) {
    TarsUniPacket encodePack = TarsUniPacket();
    encodePack.requestId = 0;
    encodePack.setTarsVersion(Const.PACKET_TYPE_TUP3);
    encodePack.setTarsPacketType(Const.PACKET_TYPE_TARSNORMAL);
    encodePack.servantName = servantName;
    encodePack.funcName = methodName;
    encodePack.put("tReq", tReq);
    Uint8List bytes = encodePack.encode();
    return bytes;
  }

  // Decode a packet that carries a response.
  TupResponse<RSP> tupResponseDecode<RSP>(String methodName, List<int> list, RSP tRsp) {
    var bytes = Uint8List.fromList(list);
    TarsUniPacket respPack = TarsUniPacket();
    respPack.decode(bytes);
    var code = respPack.get("", 0);
    RSP rsp = respPack.get<RSP>("tRsp", tRsp);
    return TupResponse<RSP>(code: code, response: rsp);
  }

  // Decode a packet with no response body.
  TupResponse<void> tupEmptyResponseDecode(String methodName, List<int> list) {
    var bytes = Uint8List.fromList(list);
    BinaryReader br = BinaryReader(bytes);
    int size = br.readInt(4);
    logger.d("size:$size");
    TarsUniPacket respPack = TarsUniPacket();
    respPack.decode(bytes);
    var code = respPack.get("", 0);
    logger.d("get tupRequest response, methodName:$methodName, code:$code");
    return TupResponse<void>(code: code);
  }
}
