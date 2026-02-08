import 'package:flutter/material.dart';
import '../models/todo_model.dart';
import '../utils/constants.dart';

class ShoppingListModal extends StatefulWidget {
  final String title;
  final List<ShoppingItem> initialItems;
  final ValueChanged<List<ShoppingItem>> onSave;

  const ShoppingListModal({
    super.key,
    required this.title,
    required this.initialItems,
    required this.onSave,
  });

  @override
  State<ShoppingListModal> createState() => _ShoppingListModalState();
}

class _ShoppingListModalState extends State<ShoppingListModal> {
  late List<ShoppingItem> _items;
  bool _isAdding = false;
  final TextEditingController _draftController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  @override
  void dispose() {
    _draftController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addItem() {
    final t = _draftController.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _items.add(ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch,
        text: t,
      ));
      _draftController.clear();
      _isAdding = false;
    });
  }

  void _openAdd() {
    setState(() => _isAdding = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _cancelAdd() {
    setState(() {
      _draftController.clear();
      _isAdding = false;
    });
  }

  void _saveAndClose() {
    widget.onSave(_items);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _saveAndClose,
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _openAdd,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: kThemeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: Column(
        children: [
          // Add form
          if (_isAdding)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFEFF6FF),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _draftController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: '項目を入力...',
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _addItem,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: kThemeColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _cancelAdd,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 16, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 16,
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.done
                                ? Colors.black26
                                : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Toggle done
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _items[index] =
                                item.copyWith(done: !item.done);
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.done
                                ? Colors.green
                                : Colors.transparent,
                            border: Border.all(
                              color: item.done
                                  ? Colors.green
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: item.done
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Delete
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _items.removeAt(index);
                          });
                        },
                        child: Icon(Icons.delete_outline,
                            size: 16, color: Colors.red[300]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
