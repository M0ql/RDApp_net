import 'package:dio/dio.dart';

import '../../../rd_app_net.dart';

class CustomInterceptor extends Interceptor {
  final _pendingRequests =
      <({RequestOptions options, RequestInterceptorHandler handler})>[];

  bool _needRefresh = false;

  CustomInterceptor(this._dio);

  final Dio _dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_needRefresh) {
      _pendingRequests.add((options: options, handler: handler));
      return;
    }
    _addToken(options);
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final requestOptions = err.response!.requestOptions;
      _needRefresh = true;
      try {
        await RDNet().onRefreshToken();
        _needRefresh = false;
      } on DioException {
        for (final request in _pendingRequests) {
          request.handler.reject(
              DioException(requestOptions: request.options, message: '需重新登录'));
        }
        _pendingRequests.clear();
        return handler.next(err);
      }

      for (final request in _pendingRequests) {
        _addToken(request.options);
        try {
          final responseOfRequest = await _dio.fetch(request.options);
          request.handler.resolve(responseOfRequest);
        } on DioException catch (e) {
          request.handler.reject(e);
        }
      }

      _addToken(requestOptions);
      try {
        final response = await _dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }
    return handler.next(err);
  }

  void _addToken(RequestOptions options) =>
      options.headers['Authorization'] = 'Bearer ${RDNet().token()}';
}
