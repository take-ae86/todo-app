import 'package:flutter/material.dart';
import '../utils/constants.dart';

class TimePickerWidget extends StatelessWidget {
  final String value; // "HH:mm"
  final ValueChanged<String> onChanged;
  final bool darkMode;

  const TimePickerWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final parts = value.split(':');
    final hour = parts[0].padLeft(2, '0');
    final min = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';

    final hours = List.generate(24, (i) => i.toString().padLeft(2, '0'));
    final mins = List.generate(60, (i) => i.toString().padLeft(2, '0'));

    final boxDecoration = BoxDecoration(
      color: darkMode ? const Color(0xFF1F2937) : const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: darkMode ? Colors.grey[700]! : const Color(0xFFDBEAFE),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: boxDecoration,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: hour,
              items: hours.map((h) {
                return DropdownMenuItem(value: h, child: Text(h));
              }).toList(),
              onChanged: (v) {
                if (v != null) onChanged('$v:$min');
              },
              style: TextStyle(
                fontSize: 18,
                color: darkMode ? Colors.white : kDarkTextColor,
              ),
              dropdownColor:
                  darkMode ? const Color(0xFF1F2937) : Colors.white,
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: 18,
              color: darkMode ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: boxDecoration,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: min,
              items: mins.map((m) {
                return DropdownMenuItem(value: m, child: Text(m));
              }).toList(),
              onChanged: (v) {
                if (v != null) onChanged('$hour:$v');
              },
              style: TextStyle(
                fontSize: 18,
                color: darkMode ? Colors.white : kDarkTextColor,
              ),
              dropdownColor:
                  darkMode ? const Color(0xFF1F2937) : Colors.white,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
