import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo_model.dart';

class StorageService {
  static const String _todosBox = 'todos';
  static const String _memosBox = 'memos';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
  }

  // ===== TODOS =====
  static Future<void> saveTodos(List<TodoItem> todos) async {
    final box = await Hive.openBox(_todosBox);
    final data = todos.map((t) => _todoToMap(t)).toList();
    await box.put('todoList', data);
  }

  static Future<List<TodoItem>> loadTodos() async {
    final box = await Hive.openBox(_todosBox);
    final raw = box.get('todoList');
    if (raw == null) return [];
    final list = (raw as List).cast<dynamic>();
    return list.map((m) => _mapToTodo(Map<String, dynamic>.from(m))).toList();
  }

  static Map<String, dynamic> _todoToMap(TodoItem t) {
    return {
      'id': t.id,
      'title': t.title,
      'category': t.category,
      'description': t.description,
      'time': t.time,
      'endTime': t.endTime,
      'endDate': t.endDate,
      'isAllDay': t.isAllDay,
      'iconColor': t.iconColor.toARGB32(),
      'date': t.date,
      'done': t.done,
      'shoppingList': t.shoppingList.map((s) => {
        'id': s.id,
        'text': s.text,
        'done': s.done,
      }).toList(),
    };
  }

  static TodoItem _mapToTodo(Map<String, dynamic> m) {
    final shopRaw = m['shoppingList'] as List? ?? [];
    final shopList = shopRaw.map((s) {
      final sm = Map<String, dynamic>.from(s);
      return ShoppingItem(
        id: sm['id'] as int,
        text: sm['text'] as String,
        done: sm['done'] as bool? ?? false,
      );
    }).toList();

    return TodoItem(
      id: m['id'] as int,
      title: m['title'] as String,
      category: m['category'] as String,
      description: m['description'] as String? ?? '',
      time: m['time'] as String,
      endTime: m['endTime'] as String?,
      endDate: m['endDate'] as String?,
      isAllDay: m['isAllDay'] as bool? ?? false,
      iconColor: Color(m['iconColor'] as int),
      date: m['date'] as String,
      done: m['done'] as bool? ?? false,
      shoppingList: shopList,
    );
  }

  // ===== MEMOS =====
  static Future<void> saveMemos(List<MemoItem> memos) async {
    final box = await Hive.openBox(_memosBox);
    final data = memos.map((m) => {'id': m.id, 'text': m.text}).toList();
    await box.put('memoList', data);
  }

  static Future<List<MemoItem>> loadMemos() async {
    final box = await Hive.openBox(_memosBox);
    final raw = box.get('memoList');
    if (raw == null) return [];
    final list = (raw as List).cast<dynamic>();
    return list.map((m) {
      final mm = Map<String, dynamic>.from(m);
      return MemoItem(id: mm['id'] as int, text: mm['text'] as String);
    }).toList();
  }

  // ===== SETTINGS =====
  static Future<void> saveDarkMode(bool value) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('darkMode', value);
  }

  static Future<bool> loadDarkMode() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('darkMode', defaultValue: false) as bool;
  }
}
