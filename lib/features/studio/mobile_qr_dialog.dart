import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:london_runner/core/services/mobile_url_service.dart';
import 'package:london_runner/core/theme/app_theme.dart';
import 'package:london_runner/features/studio/studio_ui.dart';

Future<void> showMobileQrDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (ctx) => const _MobileQrDialog(),
  );
}

Future<void> showMobileQrPoster(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _MobileQrPoster(),
    ),
  );
}

class _MobileQrDialog extends StatefulWidget {
  const _MobileQrDialog();

  @override
  State<_MobileQrDialog> createState() => _MobileQrDialogState();
}

class _MobileQrDialogState extends State<_MobileQrDialog> {
  String? _url;
  bool _loading = true;
  bool _preferLan = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final url = await MobileUrlService.resolve(preferLan: _preferLan);
    if (!mounted) return;
    setState(() {
      _url = url;
      _loading = false;
    });
  }

  bool get _qrReady => _url != null && !_url!.contains('YOUR_LAN');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: StudioTheme.card,
      title: const Text('모바일 QR'),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loading)
                const SizedBox(
                  height: 260,
                  child: Center(
                    child: CircularProgressIndicator(color: StudioTheme.neon),
                  ),
                )
              else if (_qrReady) ...[
                _QrCard(url: _url!),
                const SizedBox(height: 10),
                SelectableText(
                  _url!,
                  style: const TextStyle(
                    color: StudioTheme.neon,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else
                const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'URL을 준비하지 못했습니다.\n같은 Wi‑Fi LAN 모드를 시도하거나 잠시 후 다시 시도하세요.',
                      style: TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                _preferLan
                    ? '같은 Wi‑Fi — LAN IP QR (개발용)'
                    : '공개 URL — 길에서 지나가는 사람도 스캔 가능',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '스캔한 폰의 GPS·위치가 사용됩니다.\n'
                '네이티브 앱: HealthKit/Health Connect · 웹: 페이스 추정 HR',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() => _preferLan = !_preferLan);
            _load();
          },
          child: Text(_preferLan ? '공개 URL' : 'LAN 모드'),
        ),
        if (_qrReady)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showMobileQrPoster(context);
            },
            child: const Text('전체화면'),
          ),
        if (_qrReady)
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _url!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL 복사됨')),
              );
            },
            child: const Text('복사'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
      ],
    );
  }
}

class _MobileQrPoster extends StatefulWidget {
  const _MobileQrPoster();

  @override
  State<_MobileQrPoster> createState() => _MobileQrPosterState();
}

class _MobileQrPosterState extends State<_MobileQrPoster> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = MobileUrlService.resolve();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _urlFuture,
          builder: (context, snap) {
            final url = snap.data;
            return Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  'GEENGREEN',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const Text(
                  'QR 스캔 → 바로 런',
                  style: TextStyle(color: StudioTheme.neon, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (url != null && !url.contains('YOUR_LAN'))
                  _QrCard(url: url, size: 280)
                else
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: StudioTheme.neon),
                  ),
                const SizedBox(height: 16),
                if (url != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SelectableText(
                      url,
                      style: const TextStyle(color: StudioTheme.neon, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'GPS·위치 = 스캔한 폰 · 누구나 QR 인식 후 즉시 사용',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.url, this.size = 220});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: _QrImage(url: url, size: size),
        ),
      ),
    );
  }
}

class _QrImage extends StatelessWidget {
  const _QrImage({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final px = size.round();
      final qrUrl = '/qr.png?size=$px&data=${Uri.encodeComponent(url)}';
      return Image.network(
        qrUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: StudioTheme.neon,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _nativeQr(),
      );
    }
    return _nativeQr();
  }

  Widget _nativeQr() {
    return QrImageView(
      data: url,
      size: size,
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }
}
