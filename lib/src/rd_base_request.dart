import 'package:dio/dio.dart';

enum HttpMethod {
  get,
  post,
  delete,
}

abstract class RDBaseRequest {
  final _apiBaseUrl = 'host.ratingdog.cn';

  final _authBaseUrl = 'auth.ratingdog.cn';

  String? pathParams;

  bool useHttps = true;

  bool toAuth = false;

  Options? options;

  void Function(int, int)? onSendProgress;

  HttpMethod get httpMethod;

  String get path;

  String get _baseUrl => toAuth ? _authBaseUrl : _apiBaseUrl;

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

  var params = <String, Object?>{};

  RDBaseRequest addParam(String k, Object? v) {
    // params[k] = v is List ? jsonEncode(v) : v;
    params[k] = v;

    return this;
  }

  RDBaseRequest addAllParams(Map<String, Object?> params) {
    this.params.addAll(params);

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
