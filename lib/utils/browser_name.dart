import 'browser_name_stub.dart'
    if (dart.library.js_interop) 'browser_name_web.dart'
    as impl;

/// เบราว์เซอร์ที่มีขั้นตอนตั้งหน้าแรกให้
enum BrowserKind { chrome, edge, firefox, safari }

/// เดาเบราว์เซอร์จาก userAgent (นอกเบราว์เซอร์/เดาไม่ได้ = chrome ซึ่งคนใช้มากที่สุด)
BrowserKind detectBrowser() => browserFromUserAgent(impl.userAgent());

/// แยกจาก [detectBrowser] เพื่อให้เทสต์ส่ง userAgent เองได้
/// ลำดับสำคัญ: Edge และ Opera มีคำว่า Chrome อยู่ด้วย, Chrome มีคำว่า Safari อยู่ด้วย
BrowserKind browserFromUserAgent(String ua) {
  if (ua.contains('Edg')) return BrowserKind.edge;
  if (ua.contains('Firefox') || ua.contains('FxiOS')) return BrowserKind.firefox;
  if (ua.contains('Chrome') || ua.contains('CriOS')) return BrowserKind.chrome;
  if (ua.contains('Safari')) return BrowserKind.safari;
  return BrowserKind.chrome;
}
