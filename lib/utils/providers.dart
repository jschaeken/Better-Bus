import 'package:better_bus_dublin/utils/models.dart';
import 'package:flutter/cupertino.dart';

class SearchProvider extends ChangeNotifier {
  List<Stop> _searchResults = [];
  List<Stop> get searchResults => _searchResults;
  set searchResults(List<Stop> value) {
    _searchResults = value;
    notifyListeners();
  }

  bool _isSearching = false;
  bool get isSearching => _isSearching;
  set isSearching(bool value) {
    _isSearching = value;
    notifyListeners();
  }

  void startSearchLoading() {
    isSearching = true;
  }

  void stopSeatchLoading() {
    isSearching = false;
  }
}
