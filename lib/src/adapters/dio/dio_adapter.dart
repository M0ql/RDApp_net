import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rd_app_net/src/adapters/dio/custom_interceptor.dart';

import '../../../rd_app_net.dart';

class DioAdapter implements RDAdapter {
  final Dio _dio;

  DioAdapter._() : _dio = Dio() {
    _dio.interceptors.addAll([
      PrettyDioLogger(
        requestBody: true,
        requestHeader: false,
        enabled: RDNet().logEnabled,
        filter: RDNet().logFilter == null
            ? null
            : (options, filterArgs) => RDNet().logFilter!(options.path),
      ),
      CustomInterceptor(_dio),
    ]);
  }

  static final DioAdapter _instance = DioAdapter._();

  factory DioAdapter() => _instance;

  @override
  Future<RDNetResponse> send(RDBaseRequest request) async {
    final accessToken = RDNet().accessToken();
    final isLogin = accessToken != null && accessToken.isNotEmpty;

    final options = request.options?.copyWith(headers: request.headers) ??
        Options(headers: request.headers);

    if (request.needLogin) {
      if (!isLogin) {
        throw NeedSignInError(
            response: RDNetResponse(
                statusCode: 401, request: request, message: 'Not signed in.'));
      } else {
        if (request.permission != null && request.permission!.isNotEmpty) {
          final hasPermission =
              RDNet().permission()!.containsAll(request.permission!);
          if (hasPermission) {
            _addToken(options);
          } else {
            throw NeedAuthError(
                response: RDNetResponse(
                    statusCode: 403,
                    request: request,
                    message: 'No permission.'));
          }
        } else {
          _addToken(options);
        }
      }
    }

    _addBaseHeaders(options);

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
        HttpMethod.put => await _dio.put(request.url,
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
    options.headers ??= <String, String>{};
    options.headers!['Authorization'] = 'Bearer ${RDNet().accessToken()}';
  }

  void _addBaseHeaders(Options options) {
    options.headers ??= <String, String>{};
    options.headers!['Ratingdog.TenantId'] =
        (RDNet().tenantId() ?? 1).toString();
    options.headers!['User-Agent'] = RDNet().userAgent();
  }
}
