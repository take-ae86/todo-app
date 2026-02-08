import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'time_picker_widget.dart';
import 'shopping_list_modal.dart';

class AddEditModal extends StatefulWidget {
  final TodoItem? editingTodo;
  final DateTime? targetDate;
  final int? initialHour;
  final int? initialMinute;
  final String? initialEndTime;

  const AddEditModal({
    super.key,
    this.editingTodo,
    this.targetDate,
    this.initialHour,
    this.initialMinute,
    this.initialEndTime,
  });

  @override
  State<AddEditModal> createState() => _AddEditModalState();
}

class _AddEditModalState extends State<AddEditModal> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _category;
  late String _time;
  late String? _endTime;
  late Color _iconColor;
  late List<ShoppingItem> _shoppingListDraft;
  late bool _isAllDay;
  late DateTime _startDate;
  late DateTime? _endDate;
  late Map<String, List<DayDetail>> _dayDetails;

  bool get _isMultiDay =>
      _endDate != null &&
      TodoItem.dateToStr(_endDate!) != TodoItem.dateToStr(_startDate);

  @override
  void initState() {
    super.initState();
    final e = widget.editingTodo;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _category = e?.category ?? '買い物';
    _isAllDay = e?.isAllDay ?? false;

    if (widget.initialMinute != null) {
      final h = widget.initialMinute! ~/ 60;
      final m = widget.initialMinute! % 60;
      _time = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    } else {
      _time = e?.time ??
          (widget.initialHour != null
              ? '${widget.initialHour!.toString().padLeft(2, '0')}:00'
              : '12:00');
    }

    _endTime = widget.initialEndTime ?? e?.endTime;
    _iconColor = e?.iconColor ?? kGoogleColors[11];
    _shoppingListDraft = e?.shoppingList != null
        ? List.from(e!.shoppingList)
        : [];
    _dayDetails = e?.dayDetails != null
        ? e!.dayDetails.map((k, v) => MapEntry(k, List<DayDetail>.from(v)))
        : {};

    _startDate = e != null
        ? TodoItem.strToDate(e.date)
        : (widget.targetDate ?? DateTime.now());
    _endDate = e?.endDate != null
        ? TodoItem.strToDate(e!.endDate!)
        : _startDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) return;
    final prov = context.read<AppProvider>();

    final String saveTime;
    final String? saveEndTime;
    if (_isMultiDay) {
      saveTime = _time;
      saveEndTime = _endTime;
    } else if (_isAllDay) {
      saveTime = '00:00';
      saveEndTime = '01:00';
    } else {
      saveTime = _time;
      saveEndTime = _endTime;
    }

    final newData = TodoItem(
      id: widget.editingTodo?.id ?? DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text.trim(),
      category: _isMultiDay ? '' : _category,
      description: _isMultiDay ? '' : _descController.text,
      time: saveTime,
      endTime: saveEndTime,
      endDate: _isMultiDay ? TodoItem.dateToStr(_endDate!) : null,
      isAllDay: _isMultiDay ? false : _isAllDay,
      iconColor: _iconColor,
      date: TodoItem.dateToStr(_startDate),
      done: false,
      shoppingList: _isMultiDay ? const [] : _shoppingListDraft,
      dayDetails: _isMultiDay ? _dayDetails : const {},
    );

    if (widget.editingTodo != null) {
      prov.updateTodo(widget.editingTodo!.id, newData);
    } else {
      prov.addTodo(newData);
    }
    Navigator.of(context).pop();
  }

  void _remove() {
    if (widget.editingTodo != null) {
      final prov = context.read<AppProvider>();
      prov.removeTodo(widget.editingTodo!.id);
    }
    Navigator.of(context).pop();
  }

  void _openShoppingList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingListModal(
          title: _titleController.text.trim().isEmpty
              ? (kCategoryListName[_category] ?? 'チェックリスト')
              : _titleController.text.trim(),
          initialItems: _shoppingListDraft,
          onSave: (items) {
            setState(() {
              _shoppingListDraft = items;
            });
          },
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ja'),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
      locale: const Locale('ja'),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _openDayDetail(String dateStr) {
    final existingList = _dayDetails[dateStr] ?? <DayDetail>[];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DayTimelineScreen(
          dateStr: dateStr,
          parentTitle: _titleController.text.trim(),
          parentColor: _iconColor,
          details: existingList,
          onSave: (updatedList) {
            setState(() {
              _dayDetails = Map.from(_dayDetails);
              _dayDetails[dateStr] = updatedList;
            });
          },
        ),
      ),
    );
  }

  List<String> get _multiDayDates {
    if (!_isMultiDay) return [];
    final start = _startDate;
    final end = _endDate!;
    final List<String> dates = [];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      dates.add(TodoItem.dateToStr(d));
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final darkMode = prov.darkMode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: darkMode ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, size: 24, color: Colors.grey[400]),
                ),
                Row(
                  children: [
                    if (!_isMultiDay) ...[
                      GestureDetector(
                        onTap: _openShoppingList,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.checklist, size: 16, color: kThemeColor),
                              const SizedBox(width: 4),
                              Text(kCategoryListName[_category] ?? 'チェックリスト', style: TextStyle(fontSize: 12, color: kThemeColor)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.editingTodo != null) ...[
                      GestureDetector(
                        onTap: _remove,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                          child: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: kThemeColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: kThemeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: const Text('保存', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title input
                    TextField(
                      controller: _titleController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'タイトルを入力',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: darkMode ? Colors.white38 : Colors.grey),
                      ),
                      style: TextStyle(fontSize: 20, color: darkMode ? Colors.white : Colors.grey[800]),
                    ),
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 16),

                    // === Single-day: show category ===
                    if (!_isMultiDay) ...[
                      Text('カテゴリ', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      const SizedBox(height: 8),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                        children: kCategoryNames.map((name) {
                          final isSelected = _category == name;
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (_category != name) {
                                _shoppingListDraft = [];
                              }
                              _category = name;
                            }),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? kThemeColor : Colors.transparent),
                                color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  buildCategoryIcon(name, size: 16, color: isSelected ? kThemeColor : Colors.grey[400]!),
                                  const SizedBox(height: 4),
                                  Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? kThemeColor : Colors.grey[400])),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // All-day toggle (single-day only)
                    if (!_isMultiDay) ...[
                      Row(
                        children: [
                          Icon(Icons.wb_sunny, color: Colors.grey[400]),
                          const SizedBox(width: 12),
                          Text('終日', style: TextStyle(color: darkMode ? Colors.white : Colors.grey[800])),
                          const Spacer(),
                          Switch(
                            value: _isAllDay,
                            onChanged: (v) => setState(() => _isAllDay = v),
                            activeTrackColor: kThemeColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Start date + time
                    _DateTimeRow(
                      label: '開始',
                      date: _startDate,
                      time: (_isMultiDay || _isAllDay) ? null : _time,
                      onTapDate: _pickStartDate,
                      onTimeChanged: (_isMultiDay || _isAllDay) ? null : (v) => setState(() => _time = v),
                      darkMode: darkMode,
                    ),
                    const SizedBox(height: 8),
                    // End date + time
                    _DateTimeRow(
                      label: '終了',
                      date: _endDate,
                      time: (_isMultiDay || _isAllDay) ? null : (_endTime ?? _addOneHour(_time)),
                      onTapDate: _pickEndDate,
                      onTimeChanged: (_isMultiDay || _isAllDay) ? null : (v) => setState(() => _endTime = v),
                      darkMode: darkMode,
                    ),
                    const SizedBox(height: 16),

                    // === Color picker (both single-day and multi-day) ===
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 12),
                    Text('アイコン色を選択', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 6,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: kGoogleColors.map((c) {
                        final isSelected = _iconColor.toARGB32() == c.toARGB32();
                        return GestureDetector(
                          onTap: () => setState(() => _iconColor = c),
                          child: Container(
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.grey[400]!, width: 2) : null,
                              boxShadow: isSelected
                                  ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // === Multi-day: date buttons ===
                    if (_isMultiDay) ...[
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 12),
                      Text('日別スケジュール', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _multiDayDates.map((dateStr) {
                          final d = TodoItem.strToDate(dateStr);
                          final hasDetail = (_dayDetails[dateStr] ?? []).isNotEmpty;
                          return GestureDetector(
                            onTap: () => _openDayDetail(dateStr),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: hasDetail
                                    ? kThemeColor.withValues(alpha: 0.1)
                                    : (darkMode ? const Color(0xFF253044) : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasDetail ? kThemeColor : Colors.grey[300]!,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${d.month}/${d.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: hasDetail ? kThemeColor : (darkMode ? Colors.white70 : Colors.grey[700]),
                                    ),
                                  ),
                                  if (hasDetail) ...[
                                    const SizedBox(height: 2),
                                    Icon(Icons.check_circle, size: 12, color: kThemeColor),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // === Single-day: description ===
                    if (!_isMultiDay) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(Icons.description, color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _descController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: '詳細を追加',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: darkMode ? Colors.white38 : Colors.grey),
                              ),
                              style: TextStyle(fontSize: 14, color: darkMode ? Colors.white : Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _addOneHour(String time) {
    final parts = time.split(':');
    final h = (int.parse(parts[0]) + 1).clamp(0, 23);
    return '${h.toString().padLeft(2, '0')}:${parts[1]}';
  }
}

// === Day Timeline Screen (child timeline) ===
// Supports multiple bars per day with potchi frame, drag-move, modal creation
class _DayTimelineScreen extends StatefulWidget {
  final String dateStr;
  final String parentTitle;
  final Color parentColor;
  final List<DayDetail> details;
  final ValueChanged<List<DayDetail>> onSave;

  const _DayTimelineScreen({
    required this.dateStr,
    required this.parentTitle,
    required this.parentColor,
    required this.details,
    required this.onSave,
  });

  @override
  State<_DayTimelineScreen> createState() => _DayTimelineScreenState();
}

class _DayTimelineScreenState extends State<_DayTimelineScreen> {
  final ScrollController _scrollController = ScrollController();
  late List<DayDetail> _items; // multiple bars

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
  String? _creatingHandle;
  double _handleDragStartY = 0;
  int _handleDragStartMin = 0;

  static const double _hourHeight = 60.0;
  static const double _totalHeight = 24 * _hourHeight;
  static const double _leftMargin = 50.0;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.details);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final targetMin = _items.isNotEmpty
            ? (_items.first.isAllDay ? 0 : _items.first.timeMinutes)
            : 8 * 60;
        final scrollTo = (targetMin > 60 ? (targetMin - 60) : 0) * _hourHeight / 60;
        _scrollController.jumpTo(scrollTo.clamp(0.0, _totalHeight - 200));
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

  void _saveAll() {
    widget.onSave(List.from(_items));
  }

  // --- Bar drag (move entire bar) ---
  void _startBarDrag(DayDetail dd, double globalY) {
    setState(() {
      _draggingId = dd.id;
      _dragStartY = globalY;
      _dragStartMin = _getMinutes(dd.time);
      _dragMoved = false;
      _suppressClick = false;
    });
  }

  void _onBarDragMove(double globalY) {
    if (_draggingId == null) return;
    final deltaY = globalY - _dragStartY;
    if (deltaY.abs() >= 3) _dragMoved = true;
    final idx = _items.indexWhere((d) => d.id == _draggingId);
    if (idx < 0) return;
    final old = _items[idx];
    final nextMin = _snap15(_dragStartMin + deltaY.round());
    final duration = old.endTimeMinutes - old.timeMinutes;
    final newEndMin = (nextMin + duration).clamp(0, 1440);
    setState(() {
      _items[idx] = old.copyWith(
        time: _minutesToTime(nextMin),
        endTime: _minutesToTime(newEndMin),
      );
    });
    _saveAll();
  }

  void _endBarDrag() {
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
    final initDetail = DayDetail(
      iconColor: widget.parentColor,
      time: _minutesToTime(_createStartMin),
      endTime: _minutesToTime(_createEndMin),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DayDetailModal(
          dateStr: widget.dateStr,
          parentTitle: widget.parentTitle,
          detail: initDetail,
          onSave: (dd) {
            setState(() {
              _items.add(dd);
              _isCreating = false;
            });
            _saveAll();
          },
        ),
      ),
    );
  }

  void _openEditModal(DayDetail dd) {
    if (_suppressClick) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DayDetailModal(
          dateStr: widget.dateStr,
          parentTitle: widget.parentTitle,
          detail: dd,
          onSave: (updated) {
            setState(() {
              final idx = _items.indexWhere((d) => d.id == dd.id);
              if (idx >= 0) {
                _items[idx] = updated;
              }
            });
            _saveAll();
          },
          onDelete: () {
            setState(() {
              _items.removeWhere((d) => d.id == dd.id);
            });
            _saveAll();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final darkMode = prov.darkMode;
    final d = TodoItem.strToDate(widget.dateStr);
    final dow = d.weekday % 7;
    final weekDayStr = kWeekDays[dow];

    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF111827) : kBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back, size: 20, color: darkMode ? Colors.white : kDarkTextColor),
                        const SizedBox(width: 4),
                        Text('戻る', style: TextStyle(fontWeight: FontWeight.w500, color: darkMode ? Colors.white : kDarkTextColor)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${d.month}月${d.day}日',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: darkMode ? Colors.white : kDarkTextColor),
                      ),
                      Text(
                        '$weekDayStr曜日',
                        style: TextStyle(fontSize: 12, color: darkMode ? Colors.white38 : Colors.black38),
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
                  color: darkMode ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: darkMode ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                clipBehavior: Clip.hardEdge,
                child: Listener(
                  onPointerMove: (e) {
                    if (_draggingId != null) {
                      _onBarDragMove(e.position.dy);
                    } else if (_creatingHandle != null) {
                      _onHandleDragMove(e.position.dy);
                    }
                  },
                  onPointerUp: (_) {
                    _endBarDrag();
                    _endHandleDrag();
                  },
                  onPointerCancel: (_) {
                    _endBarDrag();
                    _endHandleDrag();
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: SizedBox(
                      height: _totalHeight,
                      child: Stack(
                        children: [
                          // Hour lines (tappable for potchi creation)
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
                                      top: BorderSide(color: darkMode ? Colors.grey[800]! : Colors.grey[100]!),
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
                          // All saved bars (draggable + tappable)
                          ..._items.map((dd) {
                            final int sMin;
                            final int eMin;
                            final String tText;
                            if (dd.isAllDay) {
                              sMin = 0;
                              eMin = 60;
                              tText = '終日';
                            } else {
                              sMin = dd.timeMinutes;
                              eMin = dd.endTimeMinutes;
                              tText = '${dd.time}〜${_minutesToTime(eMin)}';
                            }
                            final bHeight = (eMin - sMin).toDouble().clamp(30.0, _totalHeight);
                            final bColor = dd.category.isNotEmpty ? dd.iconColor : widget.parentColor;
                            final isDragging = _draggingId == dd.id;

                            return Positioned(
                              top: sMin.toDouble(),
                              left: _leftMargin + 6,
                              right: 8,
                              height: bHeight,
                              child: GestureDetector(
                                onTap: () => _openEditModal(dd),
                                onVerticalDragStart: dd.isAllDay
                                    ? null
                                    : (details) => _startBarDrag(dd, details.globalPosition.dy),
                                onVerticalDragUpdate: dd.isAllDay
                                    ? null
                                    : (details) => _onBarDragMove(details.globalPosition.dy),
                                onVerticalDragEnd: dd.isAllDay
                                    ? null
                                    : (_) => _endBarDrag(),
                                onVerticalDragCancel: dd.isAllDay
                                    ? null
                                    : () => _endBarDrag(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: bColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(left: BorderSide(color: bColor, width: 4)),
                                    boxShadow: isDragging
                                        ? [BoxShadow(color: bColor.withValues(alpha: 0.3), blurRadius: 8)]
                                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          if (dd.category.isNotEmpty)
                                            buildCategoryIcon(dd.category, size: 12, color: bColor),
                                          if (dd.category.isNotEmpty)
                                            const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              tText,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: darkMode ? Colors.white70 : Colors.grey[700],
                                              ),
                                              overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// === Day Detail Modal (child) ===
class _DayDetailModal extends StatefulWidget {
  final String dateStr;
  final String parentTitle;
  final DayDetail detail;
  final ValueChanged<DayDetail> onSave;
  final VoidCallback? onDelete;

  const _DayDetailModal({
    required this.dateStr,
    required this.parentTitle,
    required this.detail,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_DayDetailModal> createState() => _DayDetailModalState();
}

class _DayDetailModalState extends State<_DayDetailModal> {
  late String _category;
  late String _time;
  late String? _endTime;
  late bool _isAllDay;
  late TextEditingController _descController;
  late Color _iconColor;
  late List<ShoppingItem> _shoppingListDraft;

  @override
  void initState() {
    super.initState();
    final dd = widget.detail;
    _category = dd.category.isEmpty ? '買い物' : dd.category;
    _time = dd.time;
    _endTime = dd.endTime;
    _isAllDay = dd.isAllDay;
    _descController = TextEditingController(text: dd.description);
    _iconColor = dd.iconColor;
    _shoppingListDraft = List.from(dd.shoppingList);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    final String saveTime;
    final String? saveEndTime;
    if (_isAllDay) {
      saveTime = '00:00';
      saveEndTime = '01:00';
    } else {
      saveTime = _time;
      saveEndTime = _endTime;
    }

    widget.onSave(DayDetail(
      id: widget.detail.id,
      category: _category,
      time: saveTime,
      endTime: saveEndTime,
      isAllDay: _isAllDay,
      description: _descController.text,
      iconColor: _iconColor,
      shoppingList: _shoppingListDraft,
    ));
    Navigator.of(context).pop();
  }

  void _openShoppingList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingListModal(
          title: kCategoryListName[_category] ?? 'チェックリスト',
          initialItems: _shoppingListDraft,
          onSave: (items) {
            setState(() {
              _shoppingListDraft = items;
            });
          },
        ),
      ),
    );
  }

  String _addOneHour(String time) {
    final parts = time.split(':');
    final h = (int.parse(parts[0]) + 1).clamp(0, 23);
    return '${h.toString().padLeft(2, '0')}:${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final darkMode = prov.darkMode;
    final d = TodoItem.strToDate(widget.dateStr);

    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF111827) : Colors.white,
      appBar: AppBar(
        backgroundColor: darkMode ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkMode ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              '${d.year}/${d.month}/${d.day}',
              style: TextStyle(
                fontSize: 12,
                color: darkMode ? Colors.white54 : Colors.grey[600],
              ),
            ),
            Text(
              widget.parentTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: darkMode ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _openShoppingList,
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checklist, size: 18, color: kThemeColor),
                  const SizedBox(width: 4),
                  Text(kCategoryListName[_category] ?? 'チェックリスト', style: TextStyle(fontSize: 13, color: kThemeColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          if (widget.onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                widget.onDelete!();
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
              ),
            ),
          ],
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _save,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: kThemeColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('保存', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category
            Text('カテゴリ', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
              children: kCategoryNames.map((name) {
                final isSelected = _category == name;
                return GestureDetector(
                  onTap: () => setState(() {
                    if (_category != name) _shoppingListDraft = [];
                    _category = name;
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? kThemeColor : Colors.transparent),
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildCategoryIcon(name, size: 16, color: isSelected ? kThemeColor : Colors.grey[400]!),
                        const SizedBox(height: 4),
                        Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? kThemeColor : Colors.grey[400])),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // All-day toggle
            Row(
              children: [
                Icon(Icons.wb_sunny, color: Colors.grey[400]),
                const SizedBox(width: 12),
                Text('終日', style: TextStyle(color: darkMode ? Colors.white : Colors.grey[800])),
                const Spacer(),
                Switch(
                  value: _isAllDay,
                  onChanged: (v) => setState(() => _isAllDay = v),
                  activeTrackColor: kThemeColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Time picker
            if (!_isAllDay) ...[
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  TimePickerWidget(
                    value: _time,
                    onChanged: (v) => setState(() => _time = v),
                    darkMode: darkMode,
                  ),
                  const SizedBox(width: 8),
                  Text('〜', style: TextStyle(color: darkMode ? Colors.white54 : Colors.grey[600])),
                  const SizedBox(width: 8),
                  TimePickerWidget(
                    value: _endTime ?? _addOneHour(_time),
                    onChanged: (v) => setState(() => _endTime = v),
                    darkMode: darkMode,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.description, color: Colors.grey[400]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: '詳細を追加',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: darkMode ? Colors.white38 : Colors.grey),
                    ),
                    style: TextStyle(fontSize: 14, color: darkMode ? Colors.white : Colors.grey[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[200]),
            const SizedBox(height: 12),
            // Color picker
            Text('アイコン色を選択', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: kGoogleColors.map((c) {
                final isSelected = _iconColor.toARGB32() == c.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _iconColor = c),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.grey[400]!, width: 2) : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// === DateTimeRow widget ===
class _DateTimeRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String? time;
  final VoidCallback onTapDate;
  final ValueChanged<String>? onTimeChanged;
  final bool darkMode;

  const _DateTimeRow({
    required this.label,
    required this.date,
    required this.onTapDate,
    this.time,
    this.onTimeChanged,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, color: darkMode ? Colors.white54 : Colors.grey[600])),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onTapDate,
          child: Text(
            date != null
                ? '${date!.year}/${date!.month}/${date!.day}'
                : '',
            style: TextStyle(
              fontSize: 14,
              color: date != null
                  ? (darkMode ? Colors.white : Colors.grey[800])
                  : Colors.grey[400],
            ),
          ),
        ),
        if (time != null && onTimeChanged != null) ...[
          const SizedBox(width: 12),
          TimePickerWidget(
            value: time!,
            onChanged: onTimeChanged!,
            darkMode: darkMode,
          ),
        ],
      ],
    );
  }
}
