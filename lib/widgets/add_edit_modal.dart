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
    if (_isAllDay) {
      saveTime = '00:00';
      saveEndTime = '01:00';
    } else {
      saveTime = _time;
      saveEndTime = _endTime;
    }

    final newData = TodoItem(
      id: widget.editingTodo?.id ?? DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text.trim(),
      category: _category,
      description: _descController.text,
      time: saveTime,
      endTime: saveEndTime,
      endDate: _endDate != null && TodoItem.dateToStr(_endDate!) != TodoItem.dateToStr(_startDate)
          ? TodoItem.dateToStr(_endDate!)
          : null,
      isAllDay: _isAllDay,
      iconColor: _iconColor,
      date: TodoItem.dateToStr(_startDate),
      done: false,
      shoppingList: _shoppingListDraft,
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
              ? '買い物'
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
                    if (_category == '買い物')
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
                              Text('買い物リスト', style: TextStyle(fontSize: 12, color: kThemeColor)),
                            ],
                          ),
                        ),
                      ),
                    if (_category == '買い物') const SizedBox(width: 8),
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
                    // Category selection
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
                          onTap: () => setState(() => _category = name),
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
                    // Date pickers
                    _DateRow(
                      label: '開始日',
                      date: _startDate,
                      onTap: _pickStartDate,
                      darkMode: darkMode,
                    ),
                    const SizedBox(height: 8),
                    _DateRow(
                      label: '終了日',
                      date: _endDate,
                      onTap: _pickEndDate,
                      darkMode: darkMode,
                    ),
                    const SizedBox(height: 16),
                    // Time picker (hidden when all-day)
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

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool darkMode;

  const _DateRow({
    required this.label,
    required this.date,
    required this.onTap,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: darkMode ? Colors.white54 : Colors.grey[600])),
          const SizedBox(width: 12),
          Text(
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
        ],
      ),
    );
  }
}
