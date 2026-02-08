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

/// Per-day detail for multi-day TODOs
class DayDetail {
  final int id;
  final String category;
  final String time;
  final String? endTime;
  final bool isAllDay;
  final String description;
  final List<ShoppingItem> shoppingList;
  final Color iconColor;

  DayDetail({
    int? id,
    this.category = '',
    this.time = '09:00',
    this.endTime,
    this.isAllDay = false,
    this.description = '',
    this.shoppingList = const [],
    this.iconColor = const Color(0xFF5D99C6),
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch;

  DayDetail copyWith({
    int? id,
    String? category,
    String? time,
    String? endTime,
    bool? isAllDay,
    String? description,
    List<ShoppingItem>? shoppingList,
    Color? iconColor,
    bool clearEndTime = false,
  }) {
    return DayDetail(
      id: id ?? this.id,
      category: category ?? this.category,
      time: time ?? this.time,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      isAllDay: isAllDay ?? this.isAllDay,
      description: description ?? this.description,
      shoppingList: shoppingList ?? this.shoppingList,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  int get timeMinutes {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get endTimeMinutes {
    if (endTime != null) {
      final parts = endTime!.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return timeMinutes + 60;
  }
}

class TodoItem {
  final int id;
  final String title;
  final String category;
  final String description;
  final String time; // "HH:mm"
  final String? endTime; // "HH:mm" optional
  final String? endDate; // "yyyy-MM-dd" optional (for multi-day)
  final bool isAllDay;
  final Color iconColor;
  final String date; // dateStr like "2026-01-26"
  final bool done;
  final List<ShoppingItem> shoppingList;
  final Map<String, List<DayDetail>> dayDetails; // key = dateStr, value = list of details for that day

  TodoItem({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    required this.time,
    this.endTime,
    this.endDate,
    this.isAllDay = false,
    required this.iconColor,
    required this.date,
    this.done = false,
    this.shoppingList = const [],
    this.dayDetails = const {},
  });

  TodoItem copyWith({
    int? id,
    String? title,
    String? category,
    String? description,
    String? time,
    String? endTime,
    String? endDate,
    bool? isAllDay,
    Color? iconColor,
    String? date,
    bool? done,
    List<ShoppingItem>? shoppingList,
    Map<String, List<DayDetail>>? dayDetails,
    bool clearEndTime = false,
    bool clearEndDate = false,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      time: time ?? this.time,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isAllDay: isAllDay ?? this.isAllDay,
      iconColor: iconColor ?? this.iconColor,
      date: date ?? this.date,
      done: done ?? this.done,
      shoppingList: shoppingList ?? this.shoppingList,
      dayDetails: dayDetails ?? this.dayDetails,
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

  int get endTimeMinutes {
    if (endTime != null) {
      final parts = endTime!.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return timeMinutes + 60; // default 1 hour
  }

  bool get isMultiDay => endDate != null && endDate != date;

  /// All dates from start to end (for multi-day display)
  List<String> get allDates {
    if (!isMultiDay) return [date];
    final start = strToDate(date);
    final end = strToDate(endDate!);
    final List<String> dates = [];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      dates.add(dateToStr(d));
    }
    return dates;
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
