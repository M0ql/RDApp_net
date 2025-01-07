import 'package:rd_app_net/src/adapters/rd_adapter.dart';

class RDNetError<T> implements Exception {
  final int code;

  final String? message;

  final RDNetResponse<T>? response;

  final StackTrace? stackTrace;

  RDNetError(
      {required this.code,
      this.message,
      required this.response,
      this.stackTrace});
}

class NeedLoginError extends RDNetError {
  NeedLoginError(
      {super.code = 401,
      super.message = '未登录',
      super.stackTrace,
      required super.response});
}

class NeedAuthError<T> extends RDNetError<T> {
  NeedAuthError(
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
