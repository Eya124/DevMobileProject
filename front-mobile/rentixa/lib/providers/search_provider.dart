import 'package:flutter/material.dart';
import 'package:rentixa/models/ads.dart';

class SearchProvider extends ChangeNotifier {
  List<Ads> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;
  
  // Search filters
  String? _searchQuery;
  String? _selectedState;
  String? _selectedDelegation;
  String? _selectedType;
  double? _minPrice;
  double? _maxPrice;
  
  // Getters
  List<Ads> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSearched => _hasSearched;
  String? get searchQuery => _searchQuery;
  String? get selectedState => _selectedState;
  String? get selectedDelegation => _selectedDelegation;
  String? get selectedType => _selectedType;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  
  // Setters
  void setSearchResults(List<Ads> results) {
    _searchResults = results;
    notifyListeners();
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setErrorMessage(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void setHasSearched(bool searched) {
    _hasSearched = searched;
    notifyListeners();
  }
  
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void setSelectedState(String? state) {
    _selectedState = state;
    notifyListeners();
  }
  
  void setSelectedDelegation(String? delegation) {
    _selectedDelegation = delegation;
    notifyListeners();
  }
  
  void setSelectedType(String? type) {
    _selectedType = type;
    notifyListeners();
  }
  
  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }
  
  void clearSearch() {
    _searchResults = [];
    _errorMessage = null;
    _hasSearched = false;
    _searchQuery = null;
    _selectedState = null;
    _selectedDelegation = null;
    _selectedType = null;
    _minPrice = null;
    _maxPrice = null;
    notifyListeners();
  }
  
  void clearFilters() {
    _selectedState = null;
    _selectedDelegation = null;
    _selectedType = null;
    _minPrice = null;
    _maxPrice = null;
    notifyListeners();
  }
  
  bool get hasActiveFilters {
    return _selectedState != null ||
           _selectedDelegation != null ||
           _selectedType != null ||
           _minPrice != null ||
           _maxPrice != null;
  }
  
  String get searchSummary {
    if (!_hasSearched) return 'Aucune recherche effectuée';
    
    String summary = 'Recherche: "${_searchQuery ?? 'tous les annonces'}"';
    
    if (_selectedState != null) {
      summary += ' | État: $_selectedState';
    }
    if (_selectedDelegation != null) {
      summary += ' | Délégation: $_selectedDelegation';
    }
    if (_selectedType != null) {
      summary += ' | Type: $_selectedType';
    }
    if (_minPrice != null || _maxPrice != null) {
      summary += ' | Prix: ';
      if (_minPrice != null && _maxPrice != null) {
        summary += '${_minPrice} - ${_maxPrice} DT';
      } else if (_minPrice != null) {
        summary += '≥ ${_minPrice} DT';
      } else {
        summary += '≤ ${_maxPrice} DT';
      }
    }
    
    summary += ' (${_searchResults.length} résultats)';
    return summary;
  }
}
