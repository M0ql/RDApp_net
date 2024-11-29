import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rd_app_net/src/adapter/dio/custom_interceptor.dart';

import '../../../rd_app_net.dart';
import '../rd_adapter.dart';

class DioAdapter implements RDAdapter {
  final Dio _dio;

  DioAdapter._() : _dio = Dio() {
    _dio.interceptors.addAll([
      PrettyDioLogger(
        requestBody: true,
        requestHeader: false,
      ),
      CustomInterceptor(_dio),
    ]);
  }

  static final DioAdapter _instance = DioAdapter._();

  factory DioAdapter() => _instance;

  @override
  Future<RDNetResponse> send(RDBaseRequest request) async {
    final accessToken = RDNet.accessToken();
    final isLogin = accessToken != null && accessToken.isNotEmpty;

    final options = request.options?.copyWith(headers: request.headers) ??
        Options(headers: request.headers);

    if (request.needLogin) {
      if (!isLogin) {
        throw NeedLoginError(
            response: RDNetResponse(
                statusCode: 401, request: request, message: 'Not signed in.'));
      } else {
        _addToken(options);
      }
    }

    try {
      final response = switch (request.httpMethod) {
        HttpMethod.get => await _dio.get(request.url,
            queryParameters: request.params,
            options: options,
            cancelToken: RDBaseRequest.cancelToken),
        HttpMethod.post => await _dio.post(request.url,
            options: options,
            cancelToken: RDBaseRequest.cancelToken,
            data: request.params,
            onSendProgress: request.onSendProgress),
        HttpMethod.delete => await _dio.delete(request.url,
            options: options,
            cancelToken: RDBaseRequest.cancelToken,
            queryParameters: request.params,
            data: request.params),
      };

      return _buildResponse(response, request);
    } on DioException catch (e) {
      throw RDNetError(
        code: e.response?.statusCode ?? -1,
        message: e.message,
        response: _buildResponse(e.response, request),
        stackTrace: e.stackTrace,
      );
    }
  }

  RDNetResponse _buildResponse(Response? response, RDBaseRequest request) =>
      RDNetResponse(
        request: request,
        response: response,
        statusCode: response?.statusCode ?? -1,
        message: response?.statusMessage,
        data: response?.data,
      );

  void _addToken(Options options) {
    final headers = {
      'Ratingdog.TenantId': RDNet.tenantId() ?? 1,
      'User-Agent': RDNet.userAgent,
      'Authorization': 'Bearer ${RDNet.accessToken()}'
    };
    (options.headers ??= <String, dynamic>{}).addAll(headers);
  }
}
