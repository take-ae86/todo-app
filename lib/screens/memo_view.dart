import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../models/todo_model.dart';
import '../utils/constants.dart';
import '../widgets/detail_modal.dart';

class MemoView extends StatefulWidget {
  const MemoView({super.key});

  @override
  State<MemoView> createState() => _MemoViewState();
}

class _MemoViewState extends State<MemoView> {
  final TextEditingController _textController = TextEditingController();

  void _addMemo() {
    if (_textController.text.trim().isNotEmpty) {
      final prov = context.read<AppProvider>();
      prov.addMemo(MemoItem(
        id: DateTime.now().millisecondsSinceEpoch,
        text: _textController.text,
      ));
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    return Column(
      children: [
        // Input area
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: prov.darkMode ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  prov.darkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'メモを入力...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: prov.darkMode ? Colors.white38 : Colors.grey,
                  ),
                ),
                style: TextStyle(
                  color: prov.darkMode ? Colors.white : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addMemo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kThemeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Memo list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: prov.memoList.length,
            itemBuilder: (context, index) {
              final memo = prov.memoList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: prov.darkMode
                      ? const Color(0xFF1F2937)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: prov.darkMode
                        ? Colors.grey[700]!
                        : Colors.grey[200]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMemoText(
                        memo.text,
                        prov.darkMode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Detail button
                    _MemoButton(
                      icon: Icons.zoom_in,
                      color: Colors.blue,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => DetailModal(
                            title: 'メモ詳細',
                            content: memo.text,
                            darkMode: prov.darkMode,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    // Edit button (move to input)
                    _MemoButton(
                      icon: Icons.edit,
                      color: Colors.green,
                      onTap: () {
                        _textController.text = memo.text;
                        prov.removeMemo(memo.id);
                      },
                    ),
                    const SizedBox(width: 6),
                    // Delete button
                    _MemoButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () => prov.removeMemo(memo.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildMemoText(String text, bool darkMode) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    final baseColor = darkMode ? Colors.white : Colors.grey[800]!;

    if (!urlRegex.hasMatch(text)) {
      return Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: baseColor),
      );
    }

    final matches = urlRegex.allMatches(text).toList();
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: baseColor),
        ));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(color: Colors.blue),
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
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: baseColor),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MemoButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MemoButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
