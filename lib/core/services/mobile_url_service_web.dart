import 'dart:js_interop';

Future<String?> resolveMobileUrlImpl({
  required String publicUrl,
  required int port,
  bool forceLan = false,
}) async {
  final cached = _readCached();
  if (cached != null && cached.isNotEmpty && !forceLan) return cached;

  final opts = {
    'publicUrl': forceLan ? '' : publicUrl,
    'port': port,
    'forceLan': forceLan,
  }.jsify();

  final resolved = await _resolve(opts).toDart;
  return resolved?.toDart ?? _readCached();
}

@JS('window.__GEENGREEN_URL__')
external JSString? get _windowUrl;

String? _readCached() => _windowUrl?.toDart;

@JS('geengreenResolveMobileUrl')
external JSPromise<JSString?> _resolve(JSAny? opts);
