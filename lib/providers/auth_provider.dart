import 'package:flutter/material.dart';
/* Anatomy of ChangeNotifier in flutter's Provider pattern
- provided state: ie. List<String> _todos = [];
- getter method: ie. List<String> get todos => _todos;
- method to update state & notify listeners: ie. 
  void addTodo(String todo) {
    _todos.add(todo);
    notifyListeners();
  }
*/

//question: what does ChangeNotifier extend?
class AuthModel extends ChangeNotifier {
  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  void setToken(String? newToken) {
    _token = newToken;
    notifyListeners(); // Notify listeners about the change
  }

  void clearToken() {
    _token = null;
    notifyListeners(); // Notify listeners about the change
  }
}
