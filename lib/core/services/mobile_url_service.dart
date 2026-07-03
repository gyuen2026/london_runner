import 'package:flutter/foundation.dart';

import 'package:london_runner/config/api_config.dart';

import 'mobile_url_service_stub.dart'
    if (dart.library.js_interop) 'mobile_url_service_web.dart' as impl;

/// Resolves the URL encoded in mobile QR codes.
class MobileUrlService {
  /// Public HTTPS (anyone can scan) unless [preferLan] for same-Wi‑Fi dev.
  static Future<String> resolve({bool preferLan = false}) async {
    if (ApiConfig.hasPublicWebApp && !preferLan) {
      return ApiConfig.webPublicUrl;
    }

    if (kIsWeb) {
      final web = await impl.resolveMobileUrlImpl(
        publicUrl: preferLan ? '' : ApiConfig.webPublicUrl,
        port: Uri.base.hasPort ? Uri.base.port : 8086,
        forceLan: preferLan,
      );
      if (web != null && web.isNotEmpty && !web.contains('YOUR_LAN')) {
        return web.endsWith('/') ? web : '$web/';
      }

      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        final port = Uri.base.hasPort ? ':${Uri.base.port}' : '';
        return '${Uri.base.scheme}://$host$port/';
      }
    }

    if (ApiConfig.hasPublicWebApp) return ApiConfig.webPublicUrl;

    final port = Uri.base.hasPort ? Uri.base.port : 8086;
    return 'http://YOUR_LAN_IP:$port/';
  }

  static String get goPosterPath => kIsWeb ? '/go.html' : '';
}
