import 'package:flutter/material.dart';

/// TextEditingController dengan syntax highlighting Python sederhana.
class CodeController extends TextEditingController {
  CodeController({super.text});

  static final _re = RegExp(
      r'''(#.*)|("[^"\n]*"|'[^'\n]*')|\b(for|in|range|while|if|else|def|print|True|False)\b|(py\.[a-z_]+)|(\b\d+(?:\.\d+)?\b)''');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in _re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      final Color c;
      if (m.group(1) != null) {
        c = const Color(0xFF6A9955);
      } else if (m.group(2) != null) {
        c = const Color(0xFFCE9178);
      } else if (m.group(3) != null) {
        c = const Color(0xFFC586C0);
      } else if (m.group(4) != null) {
        c = const Color(0xFF4FC1FF);
      } else {
        c = const Color(0xFFB5CEA8);
      }
      spans.add(TextSpan(text: m.group(0), style: TextStyle(color: c)));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: style, children: spans);
  }
}
