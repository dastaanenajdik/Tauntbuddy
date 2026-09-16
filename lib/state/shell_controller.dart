import 'package:flutter/foundation.dart';

/// Navigation state for the app shell (side drawer + bottom nav + search).
class ShellController extends ChangeNotifier {
  int _index = 0;
  String _searchQuery = '';
  bool _drawerOpen = false;

  static const List<String> destinations = <String>[
    'Home',
    'Dashboard',
    'Library',
    'Analytics',
    'Settings',
  ];

  int get index => _index;
  String get searchQuery => _searchQuery;
  bool get drawerOpen => _drawerOpen;
  String get currentLabel => destinations[_index.clamp(0, destinations.length - 1)];

  void select(int index) {
    if (index == _index) return;
    _index = index.clamp(0, destinations.length - 1);
    _drawerOpen = false;
    notifyListeners();
  }

  void selectByLabel(String label) {
    final int found = destinations.indexOf(label);
    if (found >= 0) select(found);
  }

  void setSearchQuery(String value) {
    if (value == _searchQuery) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setDrawerOpen(bool open) {
    if (open == _drawerOpen) return;
    _drawerOpen = open;
    notifyListeners();
  }
}
