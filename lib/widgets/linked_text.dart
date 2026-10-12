import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// ข้อความหนึ่งท่อน [isLink] = เป็น URL ที่กดได้
typedef TextPiece = ({String text, bool isLink});

/// URL จบที่ช่องว่าง การขึ้นบรรทัดใหม่ เครื่องหมายคำพูด หรือตัวอักษรที่ไม่ใช่ ASCII
/// (เช่น ตัวอักษรไทยที่พิมพ์ติดกับ URL)
final RegExp _urlPattern = RegExp(
  '(?:https?)://[^\\s<>"\'\\u0080-\\uFFFF]+',
  caseSensitive: false,
);

final RegExp _hasHost = RegExp('^https?://[^/]', caseSensitive: false);

const Map<String, String> _openerOf = {')': '(', ']': '[', '}': '{'};

/// แยกข้อความเป็นท่อนธรรมดากับท่อน URL (`http://` / `https://`)
///
/// เครื่องหมายวรรคตอนท้าย URL ไม่นับเป็นส่วนของลิงก์ และวงเล็บปิดที่ไม่มีวงเล็บเปิดคู่กันใน URL
/// ก็ไม่นับ — "(https://example.com/a)" ได้ลิงก์ "https://example.com/a"
List<TextPiece> splitLinks(String text) {
  final pieces = <TextPiece>[];
  var last = 0;
  for (final m in _urlPattern.allMatches(text)) {
    final url = _trimUrl(m.group(0)!);
    // เหลือแต่ "https://" ไม่มีที่อยู่ = ไม่ใช่ลิงก์
    if (!_hasHost.hasMatch(url)) continue;
    if (m.start > last) {
      pieces.add((text: text.substring(last, m.start), isLink: false));
    }
    pieces.add((text: url, isLink: true));
    last = m.start + url.length;
  }
  if (last < text.length) {
    pieces.add((text: text.substring(last), isLink: false));
  }
  return pieces;
}

String _trimUrl(String url) {
  while (url.isNotEmpty) {
    final c = url[url.length - 1];
    final opener = _openerOf[c];
    if ('.,;:!?*'.contains(c)) {
      url = url.substring(0, url.length - 1);
    } else if (opener != null &&
        c.allMatches(url).length > opener.allMatches(url).length) {
      // วงเล็บปิดเกินวงเล็บเปิด = วงเล็บของประโยค ไม่ใช่ของ URL
      url = url.substring(0, url.length - 1);
    } else {
      break;
    }
  }
  return url;
}

/// ข้อความหลายบรรทัดที่ URL ในข้อความกดได้ (รักษาการขึ้นบรรทัดใหม่ตามที่พิมพ์)
class LinkedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color linkColor;

  /// กดลิงก์แล้วเรียกด้วย URL ที่กด
  final ValueChanged<String> onOpen;

  const LinkedText({
    super.key,
    required this.text,
    required this.style,
    required this.linkColor,
    required this.onOpen,
  });

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  late List<TextPiece> _pieces;

  /// ตัวรับการกดของแต่ละลิงก์ ต้อง dispose เอง
  final List<TapGestureRecognizer> _taps = [];

  @override
  void initState() {
    super.initState();
    _build();
  }

  @override
  void didUpdateWidget(LinkedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _build();
  }

  void _build() {
    _disposeTaps();
    _pieces = splitLinks(widget.text);
    for (final p in _pieces) {
      if (p.isLink) {
        // อ่าน widget.onOpen ตอนกด ไม่ใช่ตอนสร้าง จะได้ตัวล่าสุดเสมอ
        _taps.add(TapGestureRecognizer()..onTap = () => widget.onOpen(p.text));
      }
    }
  }

  void _disposeTaps() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _disposeTaps();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var link = 0;
    return Text.rich(
      TextSpan(
        children: [
          for (final p in _pieces)
            p.isLink
                ? TextSpan(
                    text: p.text,
                    recognizer: _taps[link++],
                    mouseCursor: SystemMouseCursors.click,
                    style: TextStyle(
                      color: widget.linkColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: widget.linkColor,
                    ),
                  )
                : TextSpan(text: p.text),
        ],
      ),
      style: widget.style,
    );
  }
}
