import 'package:flutter/material.dart';

class ShoppingItem {
  final int id;
  final String text;
  final bool done;

  ShoppingItem({required this.id, required this.text, this.done = false});

  ShoppingItem copyWith({int? id, String? text, bool? done}) {
    return ShoppingItem(
      id: id ?? this.id,
      text: text ?? this.text,
      done: done ?? this.done,
    );
  }
}

class TodoItem {
  final int id;
  final String title;
  final String category;
  final String description;
  final String time; // "HH:mm"
  final Color iconColor;
  final String date; // dateStr like "2026-01-26"
  final bool done;
  final List<ShoppingItem> shoppingList;

  TodoItem({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    required this.time,
    required this.iconColor,
    required this.date,
    this.done = false,
    this.shoppingList = const [],
  });

  TodoItem copyWith({
    int? id,
    String? title,
    String? category,
    String? description,
    String? time,
    Color? iconColor,
    String? date,
    bool? done,
    List<ShoppingItem>? shoppingList,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      time: time ?? this.time,
      iconColor: iconColor ?? this.iconColor,
      date: date ?? this.date,
      done: done ?? this.done,
      shoppingList: shoppingList ?? this.shoppingList,
    );
  }

  static String dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime strToDate(String s) {
    final parts = s.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  int get timeMinutes {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class MemoItem {
  final int id;
  final String text;

  MemoItem({required this.id, required this.text});

  MemoItem copyWith({int? id, String? text}) {
    return MemoItem(id: id ?? this.id, text: text ?? this.text);
  }
}
