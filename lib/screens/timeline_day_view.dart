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

  // Drag state for existing bars
  int? _draggingId;
  double _dragStartY = 0;
  int _dragStartMin = 0;
  bool _dragMoved = false;
  bool _suppressClick = false;

  // Creation frame state (potchi)
  bool _isCreating = false;
  int _createStartMin = 0;
  int _createEndMin = 60;
  String? _creatingHandle; // 'top' or 'bottom'

  static const double _hourHeight = 60.0;
  static const double _totalHeight = 24 * _hourHeight;
  static const double _leftMargin = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  int _snap15(int mins) {
    final snapped = ((mins + 7) ~/ 15) * 15;
    return snapped.clamp(0, 1425);
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

  // --- Bar drag (move entire bar) ---
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

    final nextMin = _snap15(_dragStartMin + deltaY.round());
    final nextTime = _minutesToTime(nextMin);

    final prov = context.read<AppProvider>();
    prov.updateTodoTime(_draggingId!, nextTime);
  }

  void _endDrag() {
    if (_draggingId == null) return;
    if (_dragMoved) {
      _suppressClick = true;
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _suppressClick = false);
      });
    }
    setState(() => _draggingId = null);
  }

  // --- Creation frame (potchi) ---
  void _startCreation(int hour) {
    final startMin = hour * 60;
    setState(() {
      _isCreating = true;
      _createStartMin = startMin;
      _createEndMin = startMin + 60;
    });
  }

  void _cancelCreation() {
    setState(() => _isCreating = false);
  }

  void _startHandleDrag(String handle) {
    setState(() => _creatingHandle = handle);
  }

  double _handleDragStartY = 0;
  int _handleDragStartMin = 0;

  void _onHandleDragMove(double globalY) {
    if (_creatingHandle == null) return;
    final delta = globalY - _handleDragStartY;
    setState(() {
      if (_creatingHandle == 'top') {
        final newStart = _snap15(_handleDragStartMin + delta.round());
        if (newStart <= _createEndMin - 15) _createStartMin = newStart;
      } else {
        final newEnd = _snap15(_handleDragStartMin + delta.round());
        if (newEnd >= _createStartMin + 15) _createEndMin = newEnd;
      }
    });
  }

  void _endHandleDrag() {
    setState(() => _creatingHandle = null);
  }

  void _openCreateModal() {
    final prov = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditModal(
        targetDate: prov.selectedDate,
        initialMinute: _createStartMin,
        initialEndTime: _minutesToTime(_createEndMin),
      ),
    ).then((_) => _cancelCreation());
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
                    Icon(Icons.arrow_back, size: 20, color: prov.darkMode ? Colors.white : kDarkTextColor),
                    const SizedBox(width: 4),
                    Text('カレンダーへ', style: TextStyle(fontWeight: FontWeight.w500, color: prov.darkMode ? Colors.white : kDarkTextColor)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${prov.selectedDate.month}月${prov.selectedDate.day}日',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: prov.darkMode ? Colors.white : kDarkTextColor),
                  ),
                  Text(
                    holiday ?? '${kWeekDays[prov.selectedDate.weekday % 7]}曜日',
                    style: TextStyle(fontSize: 12, color: holiday != null ? Colors.red : (prov.darkMode ? Colors.white38 : Colors.black38)),
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
              color: prov.darkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: prov.darkMode ? Colors.grey[800]! : Colors.grey[200]!),
            ),
            clipBehavior: Clip.hardEdge,
            child: Listener(
              onPointerMove: (e) {
                if (_draggingId != null) {
                  _onDragMove(e.position.dy);
                } else if (_creatingHandle != null) {
                  _onHandleDragMove(e.position.dy);
                }
              },
              onPointerUp: (_) {
                _endDrag();
                _endHandleDrag();
              },
              onPointerCancel: (_) {
                _endDrag();
                _endHandleDrag();
              },
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
                            onTap: () {
                              if (_isCreating) {
                                _cancelCreation();
                              } else {
                                _startCreation(h);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: prov.darkMode ? Colors.grey[800]! : Colors.grey[100]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: _leftMargin,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4, top: 2),
                                      child: Text(
                                        '$h:00',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Container(color: Colors.transparent)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      // Creation frame (potchi)
                      if (_isCreating)
                        Positioned(
                          top: _createStartMin.toDouble(),
                          left: _leftMargin + 6,
                          right: 8,
                          height: (_createEndMin - _createStartMin).toDouble(),
                          child: GestureDetector(
                            onTap: _openCreateModal,
                            child: Container(
                              decoration: BoxDecoration(
                                color: kThemeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kThemeColor, width: 1.5),
                              ),
                              child: Stack(
                                children: [
                                  // Top handle
                                  Positioned(
                                    top: -6,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: GestureDetector(
                                        onVerticalDragStart: (d) {
                                          _handleDragStartY = d.globalPosition.dy;
                                          _handleDragStartMin = _createStartMin;
                                          _startHandleDrag('top');
                                        },
                                        onVerticalDragUpdate: (d) => _onHandleDragMove(d.globalPosition.dy),
                                        onVerticalDragEnd: (_) => _endHandleDrag(),
                                        child: Container(
                                          width: 48,
                                          height: 28,
                                          color: Colors.transparent,
                                          child: Center(
                                            child: Container(
                                              width: 30,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: kThemeColor,
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Bottom handle
                                  Positioned(
                                    bottom: -6,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: GestureDetector(
                                        onVerticalDragStart: (d) {
                                          _handleDragStartY = d.globalPosition.dy;
                                          _handleDragStartMin = _createEndMin;
                                          _startHandleDrag('bottom');
                                        },
                                        onVerticalDragUpdate: (d) => _onHandleDragMove(d.globalPosition.dy),
                                        onVerticalDragEnd: (_) => _endHandleDrag(),
                                        child: Container(
                                          width: 48,
                                          height: 28,
                                          color: Colors.transparent,
                                          child: Center(
                                            child: Container(
                                              width: 30,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: kThemeColor,
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Time labels
                                  Center(
                                    child: Text(
                                      '${_minutesToTime(_createStartMin)} 〜 ${_minutesToTime(_createEndMin)}',
                                      style: TextStyle(fontSize: 11, color: kThemeColor, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Todo blocks
                      ...dayTodos.map((t) {
                        final int startMin;
                        final int endMin;
                        final String timeText;
                        final bool isMultiDay = t.isMultiDay;

                        // For multi-day todos, check if there's a child detail for this day
                        final dayDetail = isMultiDay ? t.dayDetails[dateStr] : null;

                        if (isMultiDay) {
                          // Multi-day parent bar: show title + period
                          if (dayDetail != null && !dayDetail.isAllDay) {
                            startMin = dayDetail.timeMinutes;
                            endMin = dayDetail.endTimeMinutes;
                          } else {
                            startMin = 0;
                            endMin = 60;
                          }
                          final startD = TodoItem.strToDate(t.date);
                          final endD = TodoItem.strToDate(t.endDate!);
                          timeText = '${startD.month}/${startD.day}〜${endD.month}/${endD.day}';
                        } else if (t.isAllDay) {
                          startMin = 0;
                          endMin = 60;
                          timeText = '終日';
                        } else {
                          startMin = t.timeMinutes;
                          endMin = t.endTimeMinutes;
                          timeText = '${t.time}〜${_minutesToTime(endMin)}';
                        }

                        final barHeight = (endMin - startMin).toDouble().clamp(30.0, _totalHeight);
                        final isDragging = _draggingId == t.id;

                        return Positioned(
                          top: startMin.toDouble(),
                          left: _leftMargin + 6,
                          right: 8,
                          height: barHeight,
                          child: GestureDetector(
                            onTap: () => _showEditModal(context, t),
                            onVerticalDragStart: isMultiDay ? null : (details) => _startDrag(t, details.globalPosition.dy),
                            onVerticalDragUpdate: isMultiDay ? null : (details) => _onDragMove(details.globalPosition.dy),
                            onVerticalDragEnd: isMultiDay ? null : (_) => _endDrag(),
                            onVerticalDragCancel: isMultiDay ? null : () => _endDrag(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: t.iconColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(left: BorderSide(
                                  color: t.iconColor,
                                  width: 4,
                                )),
                                boxShadow: isDragging
                                    ? [BoxShadow(color: t.iconColor.withValues(alpha: 0.3), blurRadius: 8)]
                                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)],
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
                                      color: prov.darkMode ? Colors.white : Colors.grey[700],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  if (isMultiDay)
                                    Text(
                                      timeText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: prov.darkMode ? Colors.white30 : Colors.black38,
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        buildCategoryIcon(t.category, size: 10, color: t.iconColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          t.category,
                                          style: TextStyle(fontSize: 10, color: prov.darkMode ? Colors.white54 : Colors.black54),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          timeText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: prov.darkMode ? Colors.white30 : Colors.black38,
                                            fontFeatures: const [FontFeature.tabularFigures()],
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
