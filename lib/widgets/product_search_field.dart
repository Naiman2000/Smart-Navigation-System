import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

/// Product search field with autocomplete functionality
/// Allows users to search and select from predefined products in Firebase
class ProductSearchField extends StatefulWidget {
  final Function(ProductModel) onProductSelected;
  final String? initialValue;
  final String? hintText;
  final String? labelText;

  const ProductSearchField({
    super.key,
    required this.onProductSelected,
    this.initialValue,
    this.hintText,
    this.labelText,
  });

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FirebaseService _firebaseService = FirebaseService();
  
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      _performSearch(_controller.text);
    } else if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    try {
      final results = await _firebaseService.searchProducts(query);
      if (mounted) {
        setState(() {
          _searchResults = results.take(10).toList(); // Limit to 10 results
          _isSearching = false;
        });
        _showOverlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
        debugPrint('Error searching products: $e');
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();
    
    if (!_showSuggestions || _searchResults.isEmpty) {
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No products found',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final product = _searchResults[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                _getCategoryIcon(product.category),
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                product.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              trailing: product.inStock
                                  ? Icon(
                                      Icons.check_circle,
                                      color: AppTheme.successColor,
                                      size: 20,
                                    )
                                  : Icon(
                                      Icons.cancel,
                                      color: AppTheme.errorColor,
                                      size: 20,
                                    ),
                              onTap: () {
                                _controller.text = product.name;
                                widget.onProductSelected(product);
                                _focusNode.unfocus();
                                _removeOverlay();
                                setState(() {
                                  _showSuggestions = false;
                                });
                              },
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dairy & eggs':
      case 'dairy':
        return Icons.local_dining;
      case 'meat & seafood':
      case 'meat':
        return Icons.set_meal;
      case 'bakery':
        return Icons.bakery_dining;
      case 'produce':
        return Icons.eco;
      case 'beverages':
        return Icons.local_drink;
      case 'frozen foods':
      case 'frozen':
        return Icons.ac_unit;
      case 'pantry staples':
      case 'pantry':
        return Icons.kitchen;
      case 'household items':
      case 'household':
        return Icons.home;
      case 'personal care':
        return Icons.spa;
      default:
        return Icons.shopping_bag;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText ?? 'Product Name',
          hintText: widget.hintText ?? 'Search for products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _removeOverlay();
                    setState(() {
                      _searchResults = [];
                      _showSuggestions = false;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          filled: true,
          fillColor: AppTheme.surfaceColor,
        ),
        textCapitalization: TextCapitalization.words,
        onChanged: (value) {
          if (value.isNotEmpty) {
            _performSearch(value);
          } else {
            _removeOverlay();
            setState(() {
              _searchResults = [];
              _showSuggestions = false;
            });
          }
        },
        onSubmitted: (value) {
          if (value.isNotEmpty && _searchResults.isNotEmpty) {
            // Auto-select first result if available
            widget.onProductSelected(_searchResults.first);
            _focusNode.unfocus();
            _removeOverlay();
          }
        },
      ),
    );
  }
}

