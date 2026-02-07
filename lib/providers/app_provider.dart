import 'package:flutter/material.dart';
import '../models/todo_model.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';

enum AppView { calendar, day, memo }

class AppProvider extends ChangeNotifier {
  List<TodoItem> _todos = [];
  List<MemoItem> _memoList = [];
  AppView _currentView = AppView.calendar;
  DateTime _currentDate = DateTime(2026, 1, 26);
  DateTime _selectedDate = DateTime(2026, 1, 26);
  bool _darkMode = false;
  bool _isLoaded = false;

  // Category colors
  final Map<String, Color> _catColors = {};

  AppProvider() {
    for (int i = 0; i < kCategoryNames.length; i++) {
      _catColors[kCategoryNames[i]] = kGoogleColors[i % 12];
    }
    _loadAllData();
  }

  // Load all data from Hive
  Future<void> _loadAllData() async {
    _todos = await StorageService.loadTodos();
    _memoList = await StorageService.loadMemos();
    _darkMode = await StorageService.loadDarkMode();
    _isLoaded = true;
    notifyListeners();
  }

  // Getters
  List<TodoItem> get todos => _todos;
  List<MemoItem> get memoList => _memoList;
  AppView get currentView => _currentView;
  DateTime get currentDate => _currentDate;
  DateTime get selectedDate => _selectedDate;
  bool get darkMode => _darkMode;
  Map<String, Color> get catColors => _catColors;
  bool get isLoaded => _isLoaded;

  // View navigation
  void setCurrentView(AppView view) {
    _currentView = view;
    notifyListeners();
  }

  void setCurrentDate(DateTime date) {
    _currentDate = date;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    StorageService.saveDarkMode(_darkMode);
    notifyListeners();
  }

  // Todos CRUD
  void addTodo(TodoItem todo) {
    _todos.add(todo);
    StorageService.saveTodos(_todos);
    notifyListeners();
  }

  void updateTodo(int id, TodoItem updatedTodo) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _todos[index] = updatedTodo;
      StorageService.saveTodos(_todos);
      notifyListeners();
    }
  }

  void removeTodo(int id) {
    _todos.removeWhere((t) => t.id == id);
    StorageService.saveTodos(_todos);
    notifyListeners();
  }

  void toggleTodoDone(int id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _todos[index] = _todos[index].copyWith(done: !_todos[index].done);
      StorageService.saveTodos(_todos);
      notifyListeners();
    }
  }

  void updateTodoTime(int id, String newTime) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _todos[index] = _todos[index].copyWith(time: newTime);
      StorageService.saveTodos(_todos);
      notifyListeners();
    }
  }

  void updateTodoShoppingList(int id, List<ShoppingItem> items) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _todos[index] = _todos[index].copyWith(shoppingList: items);
      StorageService.saveTodos(_todos);
      notifyListeners();
    }
  }

  List<TodoItem> todosForDate(String dateStr) {
    return _todos.where((t) => t.date == dateStr).toList();
  }

  // Memos CRUD
  void addMemo(MemoItem memo) {
    _memoList.insert(0, memo);
    StorageService.saveMemos(_memoList);
    notifyListeners();
  }

  void removeMemo(int id) {
    _memoList.removeWhere((m) => m.id == id);
    StorageService.saveMemos(_memoList);
    notifyListeners();
  }
}
