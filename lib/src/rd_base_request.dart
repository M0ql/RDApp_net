import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rd_app_net/rd_app_net.dart';
import 'package:rd_app_net/src/extensions/iterable_extension.dart';

enum HttpMethod {
  get,
  post,
  delete,
  put,
}

abstract class RDBaseRequest {
  ValueGetter<String> get _apiBaseUrl => RDNet().apiBaseUrl;

  ValueGetter<String> get _authBaseUrl => RDNet().authBaseUrl;

  String? pathParams;

  bool useHttps = true;

  bool get toAuth => false;

  Options? options;

  void Function(int, int)? onSendProgress;

  HttpMethod get httpMethod;

  String get path;

  String get _baseUrl => toAuth ? _authBaseUrl() : _apiBaseUrl();

  String get url {
    Uri uri;

    var fullPath = path;

    if (pathParams != null && pathParams!.isNotEmpty) {
      if (fullPath.endsWith('/')) {
        fullPath = path + pathParams!;
      } else {
        fullPath = '$path/$pathParams';
      }
    }

    if (useHttps) {
      uri = Uri.https(_baseUrl, fullPath);
    } else {
      uri = Uri.http(_baseUrl, fullPath);
    }

    return uri.toString();
  }

  bool get needLogin;

  Set<String>? get permission => null;

  dynamic params = <String, Object?>{};

  RDBaseRequest addParam(String k, Object? v) {
    if (v != null) (params as Map<String, Object?>)[k] = v;

    return this;
  }

  RDBaseRequest addAllParams(Map<String, Object?> params) {
    (this.params as Map<String, Object?>).addAll(params.entries
        .where((entry) => entry.value != null && entry.value != '')
        .toMap());

    return this;
  }

  var headers = <String, String>{};

  RDBaseRequest addHeader(String k, Object v) {
    headers[k] = v.toString();

    return this;
  }

  RDBaseRequest addAllHeaders(Map<String, Object> headers) {
    final newHeaders = <String, String>{};

    for (final key in headers.keys) {
      newHeaders[key] = headers[key].toString();
    }
    this.headers.addAll(newHeaders);

    return this;
  }

  static CancelToken cancelToken = CancelToken();
}
