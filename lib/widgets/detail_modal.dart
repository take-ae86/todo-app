import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class DetailModal extends StatelessWidget {
  final String title;
  final String content;
  final bool darkMode;
  final String? category;
  final String? time;

  const DetailModal({
    super.key,
    required this.title,
    required this.content,
    this.darkMode = false,
    this.category,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: darkMode ? const Color(0xFF111827) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: kThemeColor)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, color: Colors.grey[400], size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (category != null) ...[
              Text(content, style: TextStyle(fontSize: 20, color: darkMode ? Colors.white : Colors.grey[800])),
              const SizedBox(height: 8),
              Text(
                '$category${time != null ? ' ・ $time' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(minHeight: 100),
              decoration: BoxDecoration(
                color: darkMode ? const Color(0xFF1F2937) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: darkMode ? Colors.grey[700]! : Colors.grey[200]!),
              ),
              child: category != null
                  ? Text(
                      content.isEmpty ? '詳細なし' : content,
                      style: TextStyle(fontSize: 14, color: darkMode ? Colors.white70 : Colors.grey[700], height: 1.6),
                    )
                  : _buildLinkedText(
                      content,
                      TextStyle(fontSize: 18, color: darkMode ? Colors.white70 : Colors.grey[700], height: 1.6),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedText(String text, TextStyle baseStyle) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    final matches = urlRegex.allMatches(text).toList();

    if (matches.isEmpty) {
      return SelectableText(text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: baseStyle.copyWith(color: Colors.blue),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}
