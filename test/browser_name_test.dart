import 'package:flutter_test/flutter_test.dart';
import 'package:sal/utils/browser_name.dart';

void main() {
  test('เดาเบราว์เซอร์จาก userAgent', () {
    const chrome =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36';
    const edge = '$chrome Edg/142.0.0.0';
    const firefox =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:145.0) Gecko/20100101 Firefox/145.0';
    const safari =
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15';

    expect(browserFromUserAgent(chrome), BrowserKind.chrome);
    expect(browserFromUserAgent(edge), BrowserKind.edge);
    expect(browserFromUserAgent(firefox), BrowserKind.firefox);
    expect(browserFromUserAgent(safari), BrowserKind.safari);
    expect(browserFromUserAgent(''), BrowserKind.chrome);
  });
}
