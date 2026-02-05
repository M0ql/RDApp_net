import 'package:flutter/foundation.dart';

import 'adapters/rd_adapter.dart';
import 'rd_error.dart';

/// RDNet 配置类
class RDNetConfig {
  /// 需要登录回调
  ///
  /// 当遇到 401 未登录错误时调用，用于显示登录弹窗并等待用户操作
  /// - 返回 `true` 表示登录成功，框架会自动重试请求
  /// - 返回 `false` 表示用户取消登录，框架会抛出 [NotSignedInError]
  ///
  /// 注意：如果多个请求同时返回 401，只会调用一次此回调，
  /// 其他请求会等待这次登录的结果
  final Future<bool> Function() onNeedSignIn;

  /// 错误回调（可选）
  ///
  /// 当发生网络错误时调用，可以根据错误类型进行不同的处理：
  /// - [NotSignedInError] 401 未登录（仅在用户取消登录时触发）
  /// - [NoAuthError] 403 权限不足
  /// - [ServerError] 500 服务器错误
  /// - [ParamsError] 400 参数错误
  /// - [RDNetError] 其他网络错误
  final void Function(RDNetError error)? onError;

  /// 刷新 token 回调
  final AsyncCallback onRefreshToken;

  /// 获取访问令牌
  final ValueGetter<String?> accessToken;

  /// 获取租户 ID
  final ValueGetter<int?> tenantId;

  /// 获取 API 基础地址
  final ValueGetter<String> apiBaseUrl;

  /// 获取认证基础地址
  final ValueGetter<String> authBaseUrl;

  /// 获取用户代理
  final ValueGetter<String?> userAgent;

  /// 获取权限集合
  final ValueGetter<Set<String>?> permission;

  /// 网络适配器
  final RDAdapter adapter;

  /// 是否启用日志
  final bool logEnabled;

  /// 日志过滤器
  final bool Function(String url)? logFilter;

  const RDNetConfig({
    required this.onNeedSignIn,
    this.onError,
    required this.onRefreshToken,
    required this.accessToken,
    required this.tenantId,
    required this.apiBaseUrl,
    required this.authBaseUrl,
    required this.userAgent,
    required this.permission,
    required this.adapter,
    this.logEnabled = kDebugMode,
    this.logFilter,
  });

  /// 创建配置的副本，支持部分更新
  RDNetConfig copyWith({
    Future<bool> Function()? onNeedSignIn,
    void Function(RDNetError error)? onError,
    AsyncCallback? onRefreshToken,
    ValueGetter<String?>? accessToken,
    ValueGetter<int?>? tenantId,
    ValueGetter<String>? apiBaseUrl,
    ValueGetter<String>? authBaseUrl,
    ValueGetter<String?>? userAgent,
    ValueGetter<Set<String>?>? permission,
    RDAdapter? adapter,
    bool? logEnabled,
    bool Function(String url)? logFilter,
  }) {
    return RDNetConfig(
      onNeedSignIn: onNeedSignIn ?? this.onNeedSignIn,
      onError: onError ?? this.onError,
      onRefreshToken: onRefreshToken ?? this.onRefreshToken,
      accessToken: accessToken ?? this.accessToken,
      tenantId: tenantId ?? this.tenantId,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      authBaseUrl: authBaseUrl ?? this.authBaseUrl,
      userAgent: userAgent ?? this.userAgent,
      permission: permission ?? this.permission,
      adapter: adapter ?? this.adapter,
      logEnabled: logEnabled ?? this.logEnabled,
      logFilter: logFilter ?? this.logFilter,
    );
  }
}
