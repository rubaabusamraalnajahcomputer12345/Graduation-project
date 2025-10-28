import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _mainTabIndex = 0;
  int _questionsTabIndex = 0;
  bool _scrollToFavorites = false;

  int get mainTabIndex => _mainTabIndex;
  int get questionsTabIndex => _questionsTabIndex;
  bool get scrollToFavorites => _scrollToFavorites;

  void setMainTabIndex(int index) {
    _mainTabIndex = index;
    notifyListeners();
  }

  void setQuestionsTabIndex(int index) {
    _questionsTabIndex = index;
    notifyListeners();
  }

  void triggerScrollToFavorites() {
    _scrollToFavorites = true;
    notifyListeners();
  }

  void resetScrollToFavorites() {
    _scrollToFavorites = false;
    notifyListeners();
  }
} 