import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/todo_model.dart';
import '../utils/constants.dart';
import '../utils/holidays.dart';
import '../widgets/add_edit_modal.dart';

class TimelineDayView extends StatefulWidget {
  const TimelineDayView({super.key});

  @override
  State<TimelineDayView> createState() => _TimelineDayViewState();
}

class _TimelineDayViewState extends State<TimelineDayView> {
  final ScrollController _scrollController = ScrollController();

  // Drag state
  int? _draggingId;
  double _dragStartY = 0;
  int _dragStartMin = 0;
  bool _dragMoved = false;
  bool _suppressClick = false;

  static const double _hourHeight = 60.0;
  static const double _totalHeight = 24 * _hourHeight; // 1440
  static const double _leftMargin = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Scroll to 8:00 initially
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(8 * _hourHeight);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _snap30(int mins) {
    final snapped = ((mins + 15) ~/ 30) * 30;
    return snapped.clamp(0, 1430);
  }

  String _minutesToTime(int mins) {
    final m = mins.clamp(0, 1439);
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }

  int _getMinutes(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _startDrag(TodoItem todo, double globalY) {
    setState(() {
      _draggingId = todo.id;
      _dragStartY = globalY;
      _dragStartMin = _getMinutes(todo.time);
      _dragMoved = false;
      _suppressClick = false;
    });
  }

  void _onDragMove(double globalY) {
    if (_draggingId == null) return;
    final deltaY = globalY - _dragStartY;
    if (deltaY.abs() >= 3) _dragMoved = true;

    final nextMin = _snap30(_dragStartMin + deltaY.round());
    final nextTime = _minutesToTime(nextMin);

    final prov = context.read<AppProvider>();
    prov.updateTodoTime(_draggingId!, nextTime);
  }

  void _endDrag() {
    if (_draggingId == null) return;
    if (_dragMoved) {
      _suppressClick = true;
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() => _suppressClick = false);
        }
      });
    }
    setState(() {
      _draggingId = null;
    });
  }

  void _showAddModal(BuildContext context, int hour) {
    final prov = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditModal(
        targetDate: prov.selectedDate,
        initialHour: hour,
      ),
    );
  }

  void _showEditModal(BuildContext context, TodoItem todo) {
    if (_suppressClick) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditModal(editingTodo: todo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final holiday = getHoliday2026(prov.selectedDate);
    final dateStr = TodoItem.dateToStr(prov.selectedDate);
    final dayTodos = prov.todosForDate(dateStr);

    return Column(
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => prov.setCurrentView(AppView.calendar),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back,
                        size: 20,
                        color: prov.darkMode ? Colors.white : kDarkTextColor),
                    const SizedBox(width: 4),
                    Text(
                      'カレンダーへ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: prov.darkMode ? Colors.white : kDarkTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${prov.selectedDate.month}月${prov.selectedDate.day}日',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: prov.darkMode ? Colors.white : kDarkTextColor,
                    ),
                  ),
                  Text(
                    holiday ??
                        '${kWeekDays[prov.selectedDate.weekday % 7]}曜日',
                    style: TextStyle(
                      fontSize: 12,
                      color: holiday != null
                          ? Colors.red
                          : (prov.darkMode
                              ? Colors.white38
                              : Colors.black38),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Timeline
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: prov.darkMode
                  ? const Color(0xFF1F2937)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: prov.darkMode ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Listener(
              onPointerMove: (e) => _onDragMove(e.position.dy),
              onPointerUp: (_) => _endDrag(),
              onPointerCancel: (_) => _endDrag(),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SizedBox(
                  height: _totalHeight,
                  child: Stack(
                    children: [
                      // Hour lines
                      ...List.generate(24, (h) {
                        return Positioned(
                          top: h * _hourHeight,
                          left: 0,
                          right: 0,
                          height: _hourHeight,
                          child: GestureDetector(
                            onTap: () => _showAddModal(context, h),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: prov.darkMode
                                        ? Colors.grey[800]!
                                        : Colors.grey[100]!,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: _leftMargin,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          right: 4, top: 2),
                                      child: Text(
                                        '$h:00',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      // Todo blocks
                      ...dayTodos.map((t) {
                        final topPos = t.timeMinutes.toDouble();
                        final bgColor =
                            t.iconColor.withValues(alpha: 0.12);
                        final isDragging = _draggingId == t.id;
                        return Positioned(
                          top: topPos,
                          left: _leftMargin + 6,
                          right: 8,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showEditModal(context, t),
                            onVerticalDragStart: (details) =>
                                _startDrag(t, details.globalPosition.dy),
                            onVerticalDragUpdate: (details) =>
                                _onDragMove(details.globalPosition.dy),
                            onVerticalDragEnd: (_) => _endDrag(),
                            onVerticalDragCancel: () => _endDrag(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: t.iconColor,
                                    width: 4,
                                  ),
                                ),
                                boxShadow: isDragging
                                    ? [
                                        BoxShadow(
                                          color: t.iconColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 2,
                                        ),
                                      ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    t.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: prov.darkMode
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      buildCategoryIcon(
                                        t.category,
                                        size: 10,
                                        color: t.iconColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        t.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: prov.darkMode
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.time,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: prov.darkMode
                                              ? Colors.white30
                                              : Colors.black38,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
