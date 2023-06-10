import 'package:flutter/cupertino.dart';

class SearchProvider extends ChangeNotifier {
  List<dynamic> _searchResults = [];

  bool _isLoadingRoute = false;
  bool get isLoadingRoute => _isLoadingRoute;
  set isLoadingRoute(bool value) {
    _isLoadingRoute = value;
    notifyListeners();
  }

  List<dynamic> get searchResults => _searchResults;
  set searchResults(List<dynamic> value) {
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

  void stopSearchLoading() {
    isSearching = false;
  }
}
