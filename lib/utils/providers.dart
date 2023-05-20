import 'package:better_bus_dublin/utils/models.dart';
import 'package:flutter/cupertino.dart';

class SearchProvider extends ChangeNotifier {
  List<Stop> _searchResults = [];
  List<Stop> get searchResults => _searchResults;
  set searchResults(List<Stop> value) {
    _searchResults = value;
    notifyListeners();
  }
}
