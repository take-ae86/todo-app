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

  const AddEditModal({
    super.key,
    this.editingTodo,
    this.targetDate,
    this.initialHour,
  });

  @override
  State<AddEditModal> createState() => _AddEditModalState();
}

class _AddEditModalState extends State<AddEditModal> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _category;
  late String _time;
  late Color _iconColor;
  late List<ShoppingItem> _shoppingListDraft;

  @override
  void initState() {
    super.initState();
    final e = widget.editingTodo;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _category = e?.category ?? '買い物';
    _time = e?.time ??
        (widget.initialHour != null
            ? '${widget.initialHour!.toString().padLeft(2, '0')}:00'
            : '12:00');
    _iconColor = e?.iconColor ?? kGoogleColors[11];
    _shoppingListDraft = e?.shoppingList != null
        ? List.from(e!.shoppingList)
        : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime get _targetDate {
    if (widget.editingTodo != null) {
      return TodoItem.strToDate(widget.editingTodo!.date);
    }
    return widget.targetDate ?? DateTime.now();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) return;
    final prov = context.read<AppProvider>();

    final newData = TodoItem(
      id: widget.editingTodo?.id ?? DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text.trim(),
      category: _category,
      description: _descController.text,
      time: _time,
      iconColor: _iconColor,
      date: TodoItem.dateToStr(_targetDate),
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
                    // Shopping list button (only for 買い物)
                    if (_category == '買い物')
                      GestureDetector(
                        onTap: _openShoppingList,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.checklist, size: 16, color: kThemeColor),
                              const SizedBox(width: 4),
                              Text(
                                '買い物リスト',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kThemeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_category == '買い物') const SizedBox(width: 8),
                    // Delete button
                    if (widget.editingTodo != null) ...[
                      GestureDetector(
                        onTap: _remove,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delete_outline,
                              size: 18, color: Colors.red[400]),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Save button
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: kThemeColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: kThemeColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          '保存',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                        hintStyle: TextStyle(
                          color: darkMode ? Colors.white38 : Colors.grey,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        color: darkMode ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 16),
                    // Category selection
                    Text(
                      'カテゴリ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
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
                              border: Border.all(
                                color: isSelected
                                    ? kThemeColor
                                    : Colors.transparent,
                              ),
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                buildCategoryIcon(
                                  name,
                                  size: 16,
                                  color: isSelected
                                      ? kThemeColor
                                      : Colors.grey[400]!,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? kThemeColor
                                        : Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Time picker
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        TimePickerWidget(
                          value: _time,
                          onChanged: (v) => setState(() => _time = v),
                          darkMode: darkMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(Icons.description,
                              color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _descController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: '詳細を追加',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color:
                                    darkMode ? Colors.white38 : Colors.grey,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: darkMode
                                  ? Colors.white
                                  : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 12),
                    // Color picker
                    Text(
                      'アイコン色を選択',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
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
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.grey[400]!,
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ]
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
}
