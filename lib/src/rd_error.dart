import 'dart:convert';

import 'package:rd_app_net/src/adapters/rd_adapter.dart';

class RDNetError<T> implements Exception {
  final int code;

  final String? message;

  final RDNetResponse<T>? response;

  final StackTrace? stackTrace;

  RDNetError(
      {required this.code,
      this.message,
      this.response,
      this.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType(code: $code');
    if (message != null && message!.isNotEmpty) {
      buffer.write(', message: $message');
    }
    final res = response;
    if (res != null) {
      buffer.write(', statusCode: ${res.statusCode}');
      final req = res.request;
      if (req != null) {
        buffer.write(', method: ${req.httpMethod.name}');
        buffer.write(', url: ${req.url}');
      }
      if (res.data != null) {
        buffer.write(', responseData: ${_formatResponseData(res.data)}');
      }
    }
    buffer.write(')');
    return buffer.toString();
  }

  static String _formatResponseData(Object? data) {
    if (data is Map) {
      return jsonEncode(data);
    }
    return data.toString();
  }
}

class NotSignedInError extends RDNetError {
  NotSignedInError(
      {super.code = 401,
      super.message = '未登录',
      super.stackTrace,
      required super.response});
}

class NoAuthError<T> extends RDNetError<T> {
  NoAuthError(
      {super.code = 403,
      super.message,
      required super.response,
      super.stackTrace});
}

class ServerError<T> extends RDNetError<T> {
  ServerError(
      {super.code = 500,
      super.message = '服务器内部错误',
      required super.response,
      super.stackTrace});
}

class ParamsError<T> extends RDNetError<T> {
  ParamsError(
      {super.code = 400,
      super.message,
      required super.response,
      super.stackTrace});
}

class NoNetworkError extends RDNetError {
  NoNetworkError({
    super.code = -2,
    super.message = '无网络连接',
    super.response,
    super.stackTrace,
  });
}
