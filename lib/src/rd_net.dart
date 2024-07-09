import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:rd_app_net/src/rd_error.dart';

import 'adapter/dio/dio_adapter.dart';
import 'adapter/rd_adapter.dart';
import 'rd_base_request.dart';

class RDNet {
  RDNet._();

  static late final RDNet _instance;

  factory RDNet() {
    try {
      return _instance;
    } catch (e) {
      throw Exception('RDNet uninitialized');
    }
  }

  static void init(
      {required VoidCallback onNeedLoginError,
      required AsyncCallback onRefreshToken,
      required ValueGetter<String?> accessToken,
      required String apiBaseUrl,
      required String authBaseUrl}) {
    _instance = RDNet._();
    RDNet.onNeedLoginError = onNeedLoginError;
    RDNet.onRefreshToken = onRefreshToken;
    RDNet.accessToken = accessToken;
    RDNet.apiBaseUrl = apiBaseUrl;
    RDNet.authBaseUrl = authBaseUrl;
  }

  static late final VoidCallback onNeedLoginError;

  static late final AsyncCallback onRefreshToken;

  static late final ValueGetter<String?> accessToken;

  static late final String apiBaseUrl;

  static late final String authBaseUrl;

  Future fire(RDBaseRequest request) async {
    RDNetResponse response;

    StackTrace? stackTrace;

    String? message;

    int code;

    try {
      response = await DioAdapter().send(request);

      code = response.statusCode;

      message = response.message;
    } on RDNetError catch (e) {
      response = e.response;

      code = e.code;

      stackTrace = e.stackTrace;

      message = e.message;
    } catch (e) {
      rethrow;
    }

    final result = response.data;

    switch (code) {
      case 200:
        return result;

      case 401:
        onNeedLoginError();
        throw NeedLoginError(
            stackTrace: stackTrace, response: response, message: message);

      case 403:
        throw NeedAuthError(
            response: response, stackTrace: stackTrace, message: message);

      case 500:
        throw ServerError(
            response: response, stackTrace: stackTrace, message: message);

      default:
        throw RDNetError(
            code: code,
            message: message,
            response: result,
            stackTrace: stackTrace);
    }
  }
}
