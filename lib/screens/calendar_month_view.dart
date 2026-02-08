import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../utils/holidays.dart';
import '../models/todo_model.dart';

class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final y = prov.currentDate.year;
    final m = prov.currentDate.month;
    final firstWeekday = DateTime(y, m, 1).weekday % 7; // Sunday=0
    final lastDay = DateTime(y, m + 1, 0).day;

    final List<DateTime?> days = List.generate(firstWeekday, (_) => null);
    for (int i = 1; i <= lastDay; i++) {
      days.add(DateTime(y, m, i));
    }

    final rows = (days.length / 7).ceil();
    final cellCount = rows * 7;
    while (days.length < cellCount) {
      days.add(null);
    }

    // Build week rows
    final List<List<DateTime?>> weekRows = [];
    for (int r = 0; r < rows; r++) {
      weekRows.add(days.sublist(r * 7, r * 7 + 7));
    }

    return Column(
      children: [
        // Month header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left,
                        color: prov.darkMode ? Colors.white : kDarkTextColor),
                    onPressed: () =>
                        prov.setCurrentDate(DateTime(y, m - 1, 1)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$y年 $m月',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: prov.darkMode ? Colors.white : kDarkTextColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.chevron_right,
                        color: prov.darkMode ? Colors.white : kDarkTextColor),
                    onPressed: () =>
                        prov.setCurrentDate(DateTime(y, m + 1, 1)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              // Dark mode toggle
              _DarkModeToggle(prov: prov),
            ],
          ),
        ),
        // Calendar grid - uses Expanded to fill all available space evenly
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: prov.darkMode
                  ? const Color(0xFF1F2937)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                // Weekday header
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: List.generate(7, (i) {
                      final weekdayColor = i == 0
                          ? Colors.red
                          : i == 6
                              ? Colors.blue
                              : (prov.darkMode
                                  ? Colors.white54
                                  : Colors.black54);
                      return Expanded(
                        child: Center(
                          child: Text(
                            kWeekDays[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: weekdayColor,
                              shadows: [
                                Shadow(
                                  color: weekdayColor.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Each week row gets equal Expanded space
                ...weekRows.map((week) {
                  return Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: week.map((d) {
                        if (d == null) {
                          return Expanded(child: Container());
                        }
                        return Expanded(
                          child: _CalendarCell(
                            date: d,
                            prov: prov,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DarkModeToggle extends StatelessWidget {
  final AppProvider prov;
  const _DarkModeToggle({required this.prov});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => prov.toggleDarkMode(),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: prov.darkMode
              ? const Color(0xFF1E3A5F)
              : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: prov.darkMode ? Colors.transparent : Colors.white,
                shape: BoxShape.circle,
                boxShadow: prov.darkMode
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                        ),
                      ],
              ),
              child: Icon(
                Icons.wb_sunny,
                size: 14,
                color: prov.darkMode
                    ? Colors.grey
                    : const Color(0xFFEAB308),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: prov.darkMode
                    ? const Color(0xFF2563EB)
                    : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: prov.darkMode
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.dark_mode,
                size: 14,
                color: prov.darkMode ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final DateTime date;
  final AppProvider prov;

  const _CalendarCell({
    required this.date,
    required this.prov,
  });

  @override
  Widget build(BuildContext context) {
    final holiday = getHoliday2026(date);
    final dateStr = TodoItem.dateToStr(date);
    final dayTodos = prov.todosForDate(dateStr);
    final isToday = _isSameDay(date, DateTime.now());
    final dow = date.weekday % 7; // Sunday=0

    Color textColor;
    if (holiday != null || dow == 0) {
      textColor = Colors.red;
    } else if (dow == 6) {
      textColor = Colors.blue;
    } else {
      textColor = prov.darkMode ? Colors.grey[300]! : Colors.grey[700]!;
    }

    return GestureDetector(
      onTap: () {
        prov.setSelectedDate(date);
        prov.setCurrentView(AppView.day);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday
              ? (prov.darkMode
                  ? Colors.blue.withValues(alpha: 0.1)
                  : const Color(0xFFEFF6FF))
              : (prov.darkMode
                  ? const Color(0xFF253044)
                  : Colors.white),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: prov.darkMode
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Date number
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            // Holiday label - immediately below date number
            if (holiday != null)
              Text(
                holiday,
                style: const TextStyle(
                  fontSize: 6,
                  color: Colors.red,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 2),
            // Todo icons (max 3)
            if (dayTodos.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 1,
                runSpacing: 1,
                children: [
                  ...dayTodos.take(3).map((t) {
                    final iconData =
                        kCategoryIcons[t.category] ?? Icons.circle;
                    return Icon(
                      iconData,
                      size: 10,
                      color: t.iconColor,
                    );
                  }),
                  if (dayTodos.length > 3)
                    Text(
                      '+${dayTodos.length - 3}',
                      style: TextStyle(
                        fontSize: 7,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
