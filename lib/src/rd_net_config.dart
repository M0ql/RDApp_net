import 'package:flutter/foundation.dart';

import 'adapters/rd_adapter.dart';

/// RDNet 配置类
class RDNetConfig {
  /// 需要登录错误回调
  final VoidCallback onNeedLoginError;

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
    required this.onNeedLoginError,
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

  RDNetConfig copyWith({
    VoidCallback? onNeedLoginError,
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
      onNeedLoginError: onNeedLoginError ?? this.onNeedLoginError,
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
