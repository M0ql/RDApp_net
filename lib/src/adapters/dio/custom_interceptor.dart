import 'package:dio/dio.dart';

import '../../../rd_app_net.dart';

class CustomInterceptor extends Interceptor {
  final _pendingRequests = <({RequestOptions options, dynamic handler})>[];

  bool _needRefresh = false;

  CustomInterceptor(this._dio);

  final Dio _dio;

  bool _duringRetrying = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_needRefresh) {
      _pendingRequests.add((options: options, handler: handler));
      return;
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_duringRetrying) {
      final requestOptions = err.response!.requestOptions;
      if (_needRefresh) {
        _pendingRequests.add((options: requestOptions, handler: handler));
        return;
      }
      _needRefresh = true;
      try {
        await RDNet.onRefreshToken();
      } on DioException {
        for (final request in _pendingRequests) {
          request.handler.reject(DioException(
              requestOptions: request.options, message: 'Need to sign in.'));
        }
        _pendingRequests.clear();
        return handler.next(err);
      } finally {
        _needRefresh = false;
      }

      final removableRequest = [];
      _duringRetrying = true;

      for (final request in _pendingRequests) {
        _addHeaders(request.options);
        try {
          final responseOfRequest = await _dio.fetch(request.options);
          request.handler.resolve(responseOfRequest);
        } on DioException catch (e) {
          if (e.response?.statusCode == 401) {
            _pendingRequests.clear();
            _duringRetrying = false;
            request.handler.reject(e);
            return;
          }
          request.handler.reject(e);
        } finally {
          removableRequest.add(request);
        }
      }

      for (final request in removableRequest) {
        _pendingRequests.remove(request);
      }

      _addHeaders(requestOptions);
      try {
        final response = await _dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      } finally {
        _duringRetrying = false;
      }
    }
    return handler.next(err);
  }

  void _addHeaders(RequestOptions options) {
    options.headers['Ratingdog.TenantId'] = RDNet.tenantId() ?? 1;
    options.headers['User-Agent'] = RDNet.userAgent();
    options.headers['Authorization'] = 'Bearer ${RDNet.accessToken()}';
  }
}
