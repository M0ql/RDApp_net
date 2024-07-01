import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rd_app_net/src/adapter/dio/custom_interceptor.dart';

import '../../../rd_app_net.dart';
import '../../rd_error.dart';
import '../rd_adapter.dart';

class DioAdapter implements RDAdapter {
  final Dio _dio;

  DioAdapter._() : _dio = Dio() {
    _dio.interceptors.addAll([
      CustomInterceptor(_dio),
      PrettyDioLogger(
        requestBody: true,
        requestHeader: false,
      ),
    ]);
  }

  static final DioAdapter _instance = DioAdapter._();

  factory DioAdapter() => _instance;

  @override
  Future<RDNetResponse> send(RDBaseRequest request) async {
    final accessToken = RDNet().token();
    final isLogin = accessToken != null && accessToken.isNotEmpty;

    if (request.needLogin && !isLogin) {
      throw NeedLoginError(
          response: RDNetResponse(
              statusCode: 401, request: request, message: 'Not signed in.'));
    }

    final options = request.options?.copyWith(headers: request.headers) ??
        Options(headers: request.headers);

    try {
      Response response;
      switch (request.httpMethod) {
        case HttpMethod.get:
          response = await _dio.get(request.url,
              options: options, cancelToken: RDBaseRequest.cancelToken);
        case HttpMethod.post:
          response = await _dio.post(request.url,
              options: options,
              cancelToken: RDBaseRequest.cancelToken,
              data: request.params,
              onSendProgress: request.onSendProgress);
        case HttpMethod.delete:
          response = await _dio.delete(request.url,
              options: options,
              cancelToken: RDBaseRequest.cancelToken,
              data: request.params);
      }
      // final response = switch (request.httpMethod) {
      //   HttpMethod.get => await _dio.get(request.url,
      //       options: options, cancelToken: RDBaseRequest.cancelToken),
      //   HttpMethod.post => await _dio.post(request.url,
      //       options: options,
      //       cancelToken: RDBaseRequest.cancelToken,
      //       data: request.params,
      //       onSendProgress: request.onSendProgress),
      //   HttpMethod.delete => await _dio.delete(request.url,
      //       options: options,
      //       cancelToken: RDBaseRequest.cancelToken,
      //       data: request.params),
      // };

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
}
