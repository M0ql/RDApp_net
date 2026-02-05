import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:rd_app_net/src/rd_error.dart';

import 'adapters/rd_adapter.dart';
import 'rd_base_request.dart';
import 'rd_net_config.dart';

/// RDNet 网络请求管理类
/// 提供统一的网络请求接口
class RDNet {
  RDNet._(this._config);

  static RDNet? _instance;

  final RDNetConfig _config;

  factory RDNet() {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'RDNet has not been initialized. '
        'Please call RDNet.init() before using RDNet()',
      );
    }
    return instance;
  }

  static void init({
    required RDNetConfig config,
  }) {
    _instance = RDNet._(config);
  }

  /// 重置单例（主要用于测试）
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  RDNetConfig get config => _config;

  VoidCallback get onNeedLoginError => _config.onNeedLoginError;
  AsyncCallback get onRefreshToken => _config.onRefreshToken;
  ValueGetter<String?> get accessToken => _config.accessToken;
  ValueGetter<String> get apiBaseUrl => _config.apiBaseUrl;
  ValueGetter<String> get authBaseUrl => _config.authBaseUrl;
  ValueGetter<int?> get tenantId => _config.tenantId;
  ValueGetter<String?> get userAgent => _config.userAgent;
  ValueGetter<Set<String>?> get permission => _config.permission;
  bool get logEnabled => _config.logEnabled;
  bool Function(String url)? get logFilter => _config.logFilter;

  /// 发起网络请求
  ///
  /// [request] 请求对象
  /// 返回响应数据
  ///
  /// 异常：
  /// - [NeedLoginError] 401 需要登录
  /// - [NeedAuthError] 403 权限不足
  /// - [ServerError] 500 服务器错误
  /// - [RDNetError] 其他网络错误
  Future<dynamic> fire(RDBaseRequest request) async {
    RDNetResponse? response;
    StackTrace? stackTrace;
    String? message;
    int code;

    try {
      response = await _config.adapter.send(request);
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

    final result = response?.data;

    // 根据状态码处理响应
    return _handleResponse(
      code: code,
      result: result,
      response: response,
      message: message,
      stackTrace: stackTrace,
    );
  }

  /// 处理响应
  dynamic _handleResponse({
    required int code,
    required dynamic result,
    required RDNetResponse? response,
    required String? message,
    required StackTrace? stackTrace,
  }) {
    switch (code) {
      case 200:
        return result;

      case 401:
        _config.onNeedLoginError();
        throw NeedLoginError(
          stackTrace: stackTrace,
          response: response,
          message: message,
        );

      case 403:
        throw NeedAuthError(
          response: response,
          stackTrace: stackTrace,
          message: message,
        );

      case 500:
        throw ServerError(
          response: response,
          stackTrace: stackTrace,
          message: message,
        );

      default:
        throw RDNetError(
          code: code,
          message: message,
          response: response,
          stackTrace: stackTrace,
        );
    }
  }
}
