import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:network_capture/bean/http_bean.dart';
import 'package:network_capture/http/response/http_client_response_adapter.dart';

/// createTime: 2023/10/20 on 14:57
/// desc:
///
/// @author azhon
class CaptureHttpResponse extends HttpClientResponseAdapter {
  final HttpClientRequest request;
  late HttpBean httpBean;

  CaptureHttpResponse(this.request, super.origin) {
    httpBean = HttpBean(
      method: request.method,
      url: request.uri.toString(),
      requestHeaders: request.headers,
    );
  }

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    httpBean.responseHeaders = headers;
    if (!_canResolve()) {
      ///不受支持的解析类型
      return origin.transform(streamTransformer);
    }
    streamTransformer = StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        sink.add(data as S);
        _decodeResponse(data);
      },
    );
    return origin.transform(streamTransformer);
  }

  ///是否是可以解析的响应数据
  bool _canResolve() {
    final contentType = headers.contentType?.toString();
    if (contentType == null) {
      return false;
    }
    if (contentType.contains('json') ||
        contentType.contains('text') ||
        contentType.contains('xml')) {
      return true;
    }
    return false;
  }

  ///解析返回的数据
  void _decodeResponse(event) {
    String? data;
    if (event is String) {
      data = event;
    } else if (event is Uint8List) {
      data = _getEncoding()?.decode(event);
    }
    httpBean.response = data;
  }

  ///根据响应头获取编码格式
  Encoding? _getEncoding() {
    final String? charset = headers.contentType?.charset;
    return Encoding.getByName(charset ?? ContentType.text.charset);
  }
}
