import 'dart:convert';

import 'package:dio/dio.dart';

import '../rd_base_request.dart';

abstract interface class RDAdapter {
  Future<RDNetResponse> send(RDBaseRequest request);
}

class RDNetResponse<T> {
  final T? data;

  final RDBaseRequest? request;

  final Response? response;

  final int statusCode;

  final String? message;

  RDNetResponse(
      {this.request,
      this.response,
      this.data,
      this.message,
      required this.statusCode});

  @override
  String toString() {
    if (data is Map) {
      return jsonEncode(data);
    } else {
      return data.toString();
    }
  }
}
