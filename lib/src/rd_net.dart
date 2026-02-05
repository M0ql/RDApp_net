import 'dart:async';
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

  /// 是否正在登录中
  bool _isSigningIn = false;

  /// 等待登录结果的请求队列
  final List<Completer<bool>> _pendingRequests = [];

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

  /// 初始化 RDNet
  ///
  /// [config] 网络配置对象
  static void init({
    required RDNetConfig config,
  }) {
    _instance = RDNet._(config);
  }

  RDNetConfig get config => _config;

  void Function(RDNetError error)? get onError => _config.onError;
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
  /// - [NotSignedInError] 401 需要登录（用户取消登录时）
  /// - [NoAuthError] 403 权限不足
  /// - [ServerError] 500 服务器错误
  /// - [RDNetError] 其他网络错误
  Future<dynamic> fire(RDBaseRequest request) async {
    return _fireInternal(request, retryCount: 0);
  }

  /// 内部请求方法，支持重试
  Future<dynamic> _fireInternal(RDBaseRequest request,
      {required int retryCount}) async {
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

    // 特殊处理 401：尝试登录后重试
    if (code == 401 && retryCount == 0) {
      final shouldRetry = await _handleNeedSignIn();
      if (shouldRetry) {
        // 登录成功，重试请求
        return _fireInternal(request, retryCount: 1);
      } else {
        // 用户取消登录，抛出错误
        final error = NotSignedInError(
          stackTrace: stackTrace,
          response: response,
          message: message,
        );
        _config.onError?.call(error);
        throw error;
      }
    }

    // 根据状态码处理响应
    return _handleResponse(
      code: code,
      result: result,
      response: response,
      message: message,
      stackTrace: stackTrace,
    );
  }

  /// 处理需要登录的情况
  ///
  /// 返回 true 表示登录成功，false 表示用户取消
  Future<bool> _handleNeedSignIn() async {
    // 如果已经在登录中，加入等待队列
    if (_isSigningIn) {
      final completer = Completer<bool>();
      _pendingRequests.add(completer);
      return completer.future;
    }

    // 标记为登录中
    _isSigningIn = true;

    try {
      // 调用用户配置的登录回调
      final signInSuccess = await _config.onNeedSignIn();

      // 通知所有等待的请求
      for (final completer in _pendingRequests) {
        if (!completer.isCompleted) {
          completer.complete(signInSuccess);
        }
      }
      _pendingRequests.clear();

      return signInSuccess;
    } catch (e) {
      // 登录过程出错，通知所有等待的请求失败
      for (final completer in _pendingRequests) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
      _pendingRequests.clear();
      rethrow;
    } finally {
      _isSigningIn = false;
    }
  }

  /// 处理响应
  ///
  /// 注意：401 错误在 fire 方法中已特殊处理，此方法不会收到 401
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
        // 401 应该在 fire 方法中处理，这里是保底逻辑
        final error = NotSignedInError(
          stackTrace: stackTrace,
          response: response,
          message: message,
        );
        _config.onError?.call(error);
        throw error;

      case 403:
        final error = NoAuthError(
          response: response,
          stackTrace: stackTrace,
          message: message,
        );
        _config.onError?.call(error);
        throw error;

      case 500:
        final error = ServerError(
          response: response,
          stackTrace: stackTrace,
          message: message,
        );
        _config.onError?.call(error);
        throw error;

      default:
        final error = RDNetError(
          code: code,
          message: message,
          response: response,
          stackTrace: stackTrace,
        );
        _config.onError?.call(error);
        throw error;
    }
  }
}
