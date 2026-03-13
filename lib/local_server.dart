import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class LocalServer {
  late HttpServer _server;
  String _serverUrl = '';
  final Map<String, Uint8List> _cache = {};
  final Map<String, ContentType> _contentTypeCache = {};

  LocalServer() {
  }

  Future<void> start() async {
    final Completer<void> completer = Completer<void>();
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
    _serverUrl = 'http://${_server.address.host}:${_server.port}/';
    _server.listen((HttpRequest request) async {
      final pathSegments = request.uri.pathSegments;
      final String rawPath = pathSegments.join('/');
      final String pathWithoutQuery = rawPath.split('?')[0];
      final String path = pathWithoutQuery.isEmpty ? 'assets/httpdocs/index.html' : 'assets/httpdocs/$pathWithoutQuery';

      try {
        if (_cache.containsKey(path)) {
          request.response.headers.contentType = _contentTypeCache[path];
          request.response.headers.set(HttpHeaders.cacheControlHeader, 'public, max-age=31536000');
          request.response.add(_cache[path]!);
          await request.response.close();
          return;
        }

        ContentType contentType;
        if (path.endsWith('.html')) {
          contentType = ContentType.html;
        } else if (path.endsWith('.css')) {
          contentType = ContentType('text', 'css');
        } else if (path.endsWith('.js')) {
          contentType = ContentType('application', 'javascript');
        } else if (path.endsWith('.webp')) {
          contentType = ContentType('image', 'webp');
        } else if (path.endsWith('.ico')) {
          contentType = ContentType('image', 'icon');
        } else {
          contentType = ContentType('application', 'octet-stream');
        }

        final ByteData data = await rootBundle.load(path);
        final Uint8List bytes = data.buffer.asUint8List();

        _cache[path] = bytes;
        _contentTypeCache[path] = contentType;

        request.response.headers.contentType = contentType;
        request.response.headers.set(HttpHeaders.cacheControlHeader, 'public, max-age=31536000');
        request.response.add(bytes);
        await request.response.close();
      } catch (e) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('404 Not Found');
        await request.response.close();
      }
    });
    completer.complete();
    return completer.future;
  }

  void close() {
    _server.close();
  }

  String url() {
    return _serverUrl;
  }
}
