/**
 * Resolve mobile URL (meta → lan_discovery) and render QR via same-origin /qr.png.
 */
async function geengreenShowPosterQr(opts) {
  opts = opts || {};
  var meta = document.querySelector('meta[name="geengreen-public-url"]');
  var publicUrl = (opts.publicUrl || (meta ? meta.getAttribute('content') : '') || '').trim();
  var url = publicUrl ? publicUrl.replace(/\/?$/, '/') : location.origin + '/app/';

  if (window.geengreenResolveMobileUrl) {
    try {
      var resolved = await window.geengreenResolveMobileUrl({
        publicUrl: publicUrl,
        port: location.port || '8086',
        forceLan: !!opts.forceLan,
      });
      if (resolved) url = resolved;
    } catch (_) {
      /* meta/default URL is enough for public demo */
    }
  }

  var loading = document.getElementById('loading');
  var img = document.getElementById('qr');
  var link = document.getElementById('url');
  if (!url || url.indexOf('YOUR_LAN') >= 0) {
    if (loading) {
      loading.outerHTML =
        '<p style="color:#ff453a;padding:12px">URL 준비 중… Wi‑Fi/LAN 확인</p>';
    }
    return null;
  }

  if (loading) loading.hidden = true;
  if (img) {
    img.hidden = false;
    var px = opts.size || 440;
    img.src = '/qr.png?size=' + px + '&data=' + encodeURIComponent(url);
  }
  if (link) {
    link.hidden = false;
    link.textContent = url;
    link.href = url;
  }
  return url;
}
