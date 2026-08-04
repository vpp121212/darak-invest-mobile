import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/property.dart';
import '../../providers/search_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/property_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _cities = ['الرياض', 'جدة', 'مكة', 'المدينة', 'الدمام', 'الخبر', 'حائل'];
  static const _types = ['فيلا', 'شقة', 'دوبلكس', 'مكتب', 'استوديو', 'أرض', 'عمارة'];
  static const _purposes = ['بيع', 'إيجار'];
  static const _facings = ['شرقية', 'غربية', 'شمالية', 'جنوبية'];

  final TextEditingController _searchController = TextEditingController();
  bool _showAdvanced = false;

  String? _selectedCity;
  String? _selectedType;
  String? _selectedPurpose;
  String? _selectedFacing;
  int _rooms = 0;
  RangeValues _priceRange = const RangeValues(0, 5000000);
  RangeValues _areaRange = const RangeValues(0, 1000);
  String _sortKey = 'recent';

  String get _sortLabel => switch (_sortKey) {
        'price_asc' => 'السعر: من الأقل',
        'price_desc' => 'السعر: من الأعلى',
        'area_desc' => 'المساحة: من الأكبر',
        _ => 'الأحدث',
      };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
    _search();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _search(debounce: const Duration(milliseconds: 500));
  }

  void _search({Duration debounce = Duration.zero}) {
    ref.read(searchProvider.notifier).search(_buildFilters(), debounce: debounce);
  }

  SearchFilters _buildFilters() {
    return SearchFilters(
      q: _searchController.text.trim(),
      city: _selectedCity,
      type: _selectedType,
      purpose: _selectedPurpose,
      facing: _selectedFacing,
      minPrice: _priceRange.start > 0 ? _priceRange.start.round() : null,
      maxPrice: _priceRange.end < 5000000 ? _priceRange.end.round() : null,
      minArea: _areaRange.start > 0 ? _areaRange.start.round() : null,
      maxArea: _areaRange.end < 1000 ? _areaRange.end.round() : null,
      rooms: _rooms > 0 ? _rooms : null,
      sort: _sortKey,
    );
  }

  void _applyAdvanced() {
    setState(() => _showAdvanced = false);
    _search();
  }

  void _resetAdvanced() {
    setState(() {
      _selectedCity = null;
      _selectedType = null;
      _selectedPurpose = null;
      _selectedFacing = null;
      _rooms = 0;
      _priceRange = const RangeValues(0, 5000000);
      _areaRange = const RangeValues(0, 1000);
    });
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'بحث العقارات',
          style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSortRow(state.total),
          if (_showAdvanced) _buildAdvancedFilters(),
          Expanded(child: _buildResults(state)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: textMuted.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.cairo(color: textLight),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الموقع...',
                  hintStyle: GoogleFonts.cairo(color: textMuted),
                  prefixIcon: const Icon(Icons.search, color: textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _search();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _showAdvanced ? gold : cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.tune,
                color: _showAdvanced ? bgDark : gold,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortRow(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'النتائج: $total',
            style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              setState(() => _sortKey = val);
              _search();
            },
            color: cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: textMuted.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ترتيب: $_sortLabel', style: GoogleFonts.cairo(color: textLight, fontSize: 12)),
                  const Icon(Icons.arrow_drop_down, color: textMuted, size: 18),
                ],
              ),
            ),
            itemBuilder: (ctx) => [
              _buildSortItem('الأحدث', 'recent'),
              _buildSortItem('السعر: من الأقل', 'price_asc'),
              _buildSortItem('السعر: من الأعلى', 'price_desc'),
              _buildSortItem('المساحة: من الأكبر', 'area_desc'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String label, String value) {
    return PopupMenuItem(
      value: value,
      child: Text(label, style: GoogleFonts.cairo(color: textLight, fontSize: 13)),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('فلاتر متقدمة', style: GoogleFonts.cairo(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _resetAdvanced,
                child: Text('مسح الكل', style: GoogleFonts.cairo(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown('المدينة', _selectedCity, _cities, (val) => setState(() => _selectedCity = val)),
          const SizedBox(height: 10),
          _buildFilterDropdown('نوع العقار', _selectedType, _types, (val) => setState(() => _selectedType = val)),
          const SizedBox(height: 10),
          _buildFilterDropdown('الغرض', _selectedPurpose, _purposes, (val) => setState(() => _selectedPurpose = val)),
          const SizedBox(height: 10),
          _buildFilterDropdown('الواجهة', _selectedFacing, _facings, (val) => setState(() => _selectedFacing = val)),
          const SizedBox(height: 14),
          Text('نطاق السعر', style: GoogleFonts.cairo(color: textLight, fontSize: 13)),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 5000000,
            divisions: 100,
            activeColor: gold,
            inactiveColor: textMuted.withOpacity(0.3),
            labels: RangeLabels(
              '${_formatNumber(_priceRange.start.round())} ر.س',
              '${_formatNumber(_priceRange.end.round())} ر.س',
            ),
            onChanged: (val) => setState(() => _priceRange = val),
          ),
          const SizedBox(height: 10),
          Text('نطاق المساحة (م²)', style: GoogleFonts.cairo(color: textLight, fontSize: 13)),
          RangeSlider(
            values: _areaRange,
            min: 0,
            max: 1000,
            divisions: 100,
            activeColor: gold,
            inactiveColor: textMuted.withOpacity(0.3),
            labels: RangeLabels('${_areaRange.start.round()}', '${_areaRange.end.round()}'),
            onChanged: (val) => setState(() => _areaRange = val),
          ),
          const SizedBox(height: 10),
          Text('عدد الغرف', style: GoogleFonts.cairo(color: textLight, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (index) {
              final roomCount = index;
              final isSelected = _rooms == roomCount;
              final isAny = roomCount == 0;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _rooms = roomCount),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? gold : bgDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? gold : textMuted.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        isAny ? 'الكل' : '$roomCount',
                        style: GoogleFonts.cairo(
                          color: isSelected ? bgDark : textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _applyAdvanced,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text('تطبيق الفلاتر', style: GoogleFonts.cairo(color: bgDark, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String? value, List<String> items, Function(String) onTap) {
    return GestureDetector(
      onTap: () => _showPicker(label, items, onTap),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textMuted.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? label,
              style: GoogleFonts.cairo(
                color: value != null ? textLight : textMuted,
                fontSize: 14,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: value != null ? gold : textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  void _showPicker(String label, List<String> items, Function(String) onTap) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: textMuted, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('اختر $label', style: GoogleFonts.cairo(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...items.map((item) => ListTile(
                title: Text(item, style: GoogleFonts.cairo(color: textLight)),
                onTap: () {
                  onTap(item);
                  context.pop();
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildResults(SearchState state) {
    if (state.isSearching && state.properties.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 140,
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: CircularProgressIndicator(color: gold.withOpacity(0.3), strokeWidth: 2)),
        ),
      );
    }
    if (state.error != null && state.properties.isEmpty) {
      return _buildMessage(
        icon: Icons.cloud_off,
        title: 'تعذّر البحث',
        subtitle: state.error!,
      );
    }
    if (state.properties.isEmpty) {
      return _buildMessage(
        icon: Icons.search_off,
        title: 'لا توجد نتائج',
        subtitle: 'جرب تغيير معايير البحث',
      );
    }
    final properties = state.properties;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard(
          property: property,
          onTap: () => _openDetail(property),
        );
      },
    );
  }

  Widget _buildMessage({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: textMuted),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.cairo(color: textMuted, fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _openDetail(Property property) {
    context.push('/property', extra: property);
  }

  String _formatNumber(num value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
