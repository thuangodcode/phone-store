import 'package:flutter/material.dart';
import '../../../../core/models/brand.dart';
import '../../../../core/services/api_service.dart';

class BrandSelector extends StatefulWidget {
  final Function(String brandId, String brandName)? onBrandSelected;
  const BrandSelector({super.key, this.onBrandSelected});

  @override
  State<BrandSelector> createState() => _BrandSelectorState();
}

class _BrandSelectorState extends State<BrandSelector> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _displayBrands = [];

  // Fallback mock brands in case API is offline or slow
  final List<Map<String, dynamic>> _mockBrands = [
    {'id': '', 'name': 'Tất cả', 'icon': Icons.phone_android},
    {'id': 'apple', 'name': 'Apple', 'icon': Icons.apple},
    {'id': 'samsung', 'name': 'Samsung', 'icon': Icons.star_border},
    {'id': 'xiaomi', 'name': 'Xiaomi', 'icon': Icons.adjust},
    {'id': 'oppo', 'name': 'OPPO', 'icon': Icons.opacity},
    {'id': 'vivo', 'name': 'Vivo', 'icon': Icons.vibration},
  ];

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  Future<void> _fetchBrands() async {
    setState(() {
      _isLoading = true;
    });

    final brands = await ApiService.getBrands();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (brands.isNotEmpty) {
          // Initialize list with "Tất cả" option
          _displayBrands = [
            {'id': '', 'name': 'Tất cả', 'icon': Icons.phone_android}
          ];
          // Add brands retrieved from backend
          for (var brand in brands) {
            _displayBrands.add({
              'id': brand.id,
              'name': brand.name,
              'icon': _getIconForBrand(brand.name),
            });
          }
        } else {
          // Fallback to mock data on error/empty
          _displayBrands = _mockBrands;
        }
      });
    }
  }

  IconData _getIconForBrand(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('apple') || lowerName.contains('iphone')) return Icons.apple;
    if (lowerName.contains('samsung')) return Icons.star_border;
    if (lowerName.contains('xiaomi')) return Icons.adjust;
    if (lowerName.contains('oppo')) return Icons.opacity;
    if (lowerName.contains('vivo')) return Icons.vibration;
    return Icons.phone_iphone;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _displayBrands.isEmpty) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _displayBrands.length,
        itemBuilder: (context, index) {
          final brand = _displayBrands[index];
          final isActive = _selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  if (widget.onBrandSelected != null) {
                    widget.onBrandSelected!(brand['id'] ?? '', brand['name'] ?? '');
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF1F2937),
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        brand['icon'] as IconData,
                        color: isActive
                            ? const Color(0xFFF9FAFB)
                            : const Color(0xFF9CA3AF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        brand['name'],
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFFF9FAFB)
                              : const Color(0xFFE5E7EB),
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
