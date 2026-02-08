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
    final firstWeekday = DateTime(y, m, 1).weekday % 7;
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

    final List<List<DateTime?>> weekRows = [];
    for (int r = 0; r < rows; r++) {
      weekRows.add(days.sublist(r * 7, r * 7 + 7));
    }

    final multiDayTodos = prov.todos.where((t) => t.isMultiDay).toList();

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
                    icon: Icon(Icons.chevron_left, color: prov.darkMode ? Colors.white : kDarkTextColor),
                    onPressed: () => prov.setCurrentDate(DateTime(y, m - 1, 1)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$y年 $m月',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: prov.darkMode ? Colors.white : kDarkTextColor),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: prov.darkMode ? Colors.white : kDarkTextColor),
                    onPressed: () => prov.setCurrentDate(DateTime(y, m + 1, 1)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              _DarkModeToggle(prov: prov),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: prov.darkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
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
                              : (prov.darkMode ? Colors.white54 : Colors.black54);
                      return Expanded(
                        child: Center(
                          child: Text(
                            kWeekDays[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: weekdayColor,
                              shadows: [Shadow(color: weekdayColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                ...weekRows.map((week) {
                  return Expanded(
                    child: _WeekRowWithBars(week: week, prov: prov, multiDayTodos: multiDayTodos),
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

class _WeekRowWithBars extends StatelessWidget {
  final List<DateTime?> week;
  final AppProvider prov;
  final List<TodoItem> multiDayTodos;

  const _WeekRowWithBars({required this.week, required this.prov, required this.multiDayTodos});

  @override
  Widget build(BuildContext context) {
    final weekStart = week.firstWhere((d) => d != null, orElse: () => null);
    final weekEnd = week.lastWhere((d) => d != null, orElse: () => null);
    if (weekStart == null || weekEnd == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: week.map((d) {
          if (d == null) return Expanded(child: Container());
          return Expanded(child: _CalendarCell(date: d, prov: prov));
        }).toList(),
      );
    }

    final weekDateStrs = week.where((d) => d != null).map((d) => TodoItem.dateToStr(d!)).toSet();

    final List<_BarInfo> bars = [];
    for (final todo in multiDayTodos) {
      final allDates = todo.allDates;
      final overlapping = allDates.where((d) => weekDateStrs.contains(d)).toList();
      if (overlapping.isEmpty) continue;

      int startCol = -1;
      int endCol = -1;
      for (int i = 0; i < 7; i++) {
        if (week[i] != null) {
          final ds = TodoItem.dateToStr(week[i]!);
          if (overlapping.contains(ds)) {
            if (startCol == -1) startCol = i;
            endCol = i;
          }
        }
      }
      if (startCol >= 0) {
        bars.add(_BarInfo(todo: todo, startCol: startCol, endCol: endCol));
      }
    }

    final Map<String, int> multiDayBarCount = {};
    for (final bar in bars) {
      for (int c = bar.startCol; c <= bar.endCol; c++) {
        if (week[c] != null) {
          final ds = TodoItem.dateToStr(week[c]!);
          multiDayBarCount[ds] = (multiDayBarCount[ds] ?? 0) + 1;
        }
      }
    }

    final multiDayIds = bars.map((b) => b.todo.id).toSet();

    // Check if any day in this week has a holiday
    final weekHasHoliday = week.any((d) => d != null && getHoliday2026(d) != null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        final cellHeight = constraints.maxHeight;
        // If any day in the week has a holiday, push bars below the holiday label + gap
        final barStartY = weekHasHoliday ? 38.0 : 24.0;
        const barH = 14.0;
        const barGap = 1.0;

        return Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(7, (i) {
                final d = week[i];
                if (d == null) return Expanded(child: Container());
                return Expanded(
                  child: _CalendarCell(
                    date: d,
                    prov: prov,
                    multiDayIds: multiDayIds,
                    multiDayBarSlots: multiDayBarCount[TodoItem.dateToStr(d)] ?? 0,
                  ),
                );
              }),
            ),
            ...List.generate(bars.length, (barIdx) {
              final bar = bars[barIdx];
              final left = bar.startCol * cellWidth + 3;
              final right = (6 - bar.endCol) * cellWidth + 3;
              final top = barStartY + barIdx * (barH + barGap);

              if (top + barH > cellHeight) return const SizedBox.shrink();

              final isStart = bar.todo.date ==
                  (week[bar.startCol] != null ? TodoItem.dateToStr(week[bar.startCol]!) : '');

              return Positioned(
                top: top,
                left: left,
                right: right,
                height: barH,
                child: GestureDetector(
                  onTap: () {
                    prov.setSelectedDate(TodoItem.strToDate(bar.todo.date));
                    prov.setCurrentView(AppView.day);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bar.todo.iconColor.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.horizontal(
                        left: isStart ? const Radius.circular(4) : Radius.zero,
                        right: bar.todo.endDate ==
                                (week[bar.endCol] != null ? TodoItem.dateToStr(week[bar.endCol]!) : '')
                            ? const Radius.circular(4)
                            : Radius.zero,
                      ),
                      border: Border(
                        left: BorderSide(
                          color: isStart ? bar.todo.iconColor : Colors.transparent,
                          width: isStart ? 2 : 0,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Row(
                      children: [
                        if (isStart)
                          buildCategoryIcon(bar.todo.category, size: 9, color: bar.todo.iconColor),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _BarInfo {
  final TodoItem todo;
  final int startCol;
  final int endCol;
  _BarInfo({required this.todo, required this.startCol, required this.endCol});
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
          color: prov.darkMode ? const Color(0xFF1E3A5F) : const Color(0xFFE5E7EB),
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
                boxShadow: prov.darkMode ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2)],
              ),
              child: Icon(Icons.wb_sunny, size: 14, color: prov.darkMode ? Colors.grey : const Color(0xFFEAB308)),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: prov.darkMode ? const Color(0xFF2563EB) : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: prov.darkMode ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2)] : null,
              ),
              child: Icon(Icons.dark_mode, size: 14, color: prov.darkMode ? Colors.white : Colors.grey),
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
  final Set<int> multiDayIds;
  final int multiDayBarSlots;

  const _CalendarCell({
    required this.date,
    required this.prov,
    this.multiDayIds = const {},
    this.multiDayBarSlots = 0,
  });

  @override
  Widget build(BuildContext context) {
    final holiday = getHoliday2026(date);
    final dateStr = TodoItem.dateToStr(date);
    final dayTodos = prov.todosForDate(dateStr);
    final singleDayTodos = dayTodos.where((t) => !multiDayIds.contains(t.id)).toList();
    final isToday = _isSameDay(date, DateTime.now());
    final dow = date.weekday % 7;

    Color textColor;
    if (holiday != null || dow == 0) {
      textColor = Colors.red;
    } else if (dow == 6) {
      textColor = Colors.blue;
    } else {
      textColor = prov.darkMode ? Colors.grey[300]! : Colors.grey[700]!;
    }

    // Always allow 4 mini bars (holiday label is small enough)
    final maxMini = (4 - multiDayBarSlots).clamp(0, 4);

    return GestureDetector(
      onTap: () {
        prov.setSelectedDate(date);
        prov.setCurrentView(AppView.day);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday
              ? (prov.darkMode ? Colors.blue.withValues(alpha: 0.1) : const Color(0xFFEFF6FF))
              : (prov.darkMode ? const Color(0xFF253044) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: prov.darkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${date.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
            if (holiday != null)
              Text(
                holiday,
                style: const TextStyle(fontSize: 6, color: Colors.red, height: 1.2),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            if (holiday != null) const SizedBox(height: 2),
            if (multiDayBarSlots > 0) SizedBox(height: multiDayBarSlots * 15.0),
            // Single-day todo mini bars (height 16, max 4, icon + time/終日)
            if (singleDayTodos.isNotEmpty && maxMini > 0)
              ...singleDayTodos.take(maxMini).map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Container(
                    height: holiday != null ? 14 : 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: t.iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border(left: BorderSide(color: t.iconColor, width: 2)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 2),
                        buildCategoryIcon(t.category, size: 10, color: t.iconColor),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            t.isAllDay ? '終日' : t.time,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w500,
                              color: prov.darkMode ? Colors.white70 : Colors.grey[700],
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            if (singleDayTodos.length > maxMini && maxMini > 0)
              Text('+${singleDayTodos.length - maxMini}', style: TextStyle(fontSize: 7, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
