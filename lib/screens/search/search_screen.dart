import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color bgDark = Color(0xFF020617);
const Color gold = Color(0xFFD4AF37);
const Color cardDark = Color(0xFF0F172A);
const Color textLight = Color(0xFFF8FAFC);
const Color textMuted = Color(0xFF94A3B8);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showAdvanced = false;
  String _sortBy = 'الأحدث';
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedType;
  String? _selectedPurpose;
  String? _selectedFacing;
  RangeValues _priceRange = const RangeValues(0, 5000000);
  RangeValues _areaRange = const RangeValues(0, 1000);
  int _rooms = 0;

  final List<Map<String, dynamic>> _results = const [
    {
      'title': 'فيلا فاخرة حي النرجس',
      'price': 2500000,
      'city': 'الرياض',
      'district': 'حي النرجس',
      'rooms': 6,
      'baths': 4,
      'area': 450,
      'image': 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
      'purpose': 'بيع',
      'trusted': true,
    },
    {
      'title': 'شقة أنيقة حي الملقا',
      'price': 850000,
      'city': 'الرياض',
      'district': 'حي الملقا',
      'rooms': 3,
      'baths': 2,
      'area': 180,
      'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      'purpose': 'بيع',
      'trusted': true,
    },
    {
      'title': 'دوبلكس حي الياسمين',
      'price': 12000,
      'city': 'جدة',
      'district': 'حي الياسمين',
      'rooms': 4,
      'baths': 3,
      'area': 250,
      'image': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      'purpose': 'إيجار',
      'trusted': false,
    },
  ];

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
            _buildSortRow(),
            if (_showAdvanced) _buildAdvancedFilters(),
            Expanded(
              child: _results.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) => _buildResultCard(_results[index]),
                    ),
            ),
          ],
        ),
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

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'النتائج: ${_results.length}',
            style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
          ),
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => _sortBy = val),
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
                  Text('ترتيب: $_sortBy', style: GoogleFonts.cairo(color: textLight, fontSize: 12)),
                  const Icon(Icons.arrow_drop_down, color: textMuted, size: 18),
                ],
              ),
            ),
            itemBuilder: (ctx) => [
              _buildSortItem('الأحدث'),
              _buildSortItem('السعر: من الأقل'),
              _buildSortItem('السعر: من الأعلى'),
              _buildSortItem('المساحة: من الأكبر'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String label) {
    return PopupMenuItem(
      value: label,
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
                onPressed: () {
                  setState(() {
                    _selectedCity = null;
                    _selectedDistrict = null;
                    _selectedType = null;
                    _selectedPurpose = null;
                    _selectedFacing = null;
                    _priceRange = const RangeValues(0, 5000000);
                    _areaRange = const RangeValues(0, 1000);
                    _rooms = 0;
                  });
                },
                child: Text('مسح الكل', style: GoogleFonts.cairo(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterDropdown('المدينة', _selectedCity, ['الرياض', 'جدة', 'الدمام', 'مكة', 'المدينة'], (val) {
            setState(() => _selectedCity = val);
          }),
          const SizedBox(height: 10),
          _buildFilterDropdown('الحي', _selectedDistrict, ['حي النرجس', 'حي الملقا', 'حي الراكة'], (val) {
            setState(() => _selectedDistrict = val);
          }),
          const SizedBox(height: 10),
          _buildFilterDropdown('نوع العقار', _selectedType, ['فيلا', 'شقة', 'دوبلكس', 'مكتب', 'استوديو', 'أرض'], (val) {
            setState(() => _selectedType = val);
          }),
          const SizedBox(height: 10),
          _buildFilterDropdown('الغرض', _selectedPurpose, ['بيع', 'إيجار'], (val) {
            setState(() => _selectedPurpose = val);
          }),
          const SizedBox(height: 10),
          _buildFilterDropdown('الواجهة', _selectedFacing, ['شرقية', 'غربية', 'شمالية', 'جنوبية'], (val) {
            setState(() => _selectedFacing = val);
          }),
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
              '${_formatPrice(_priceRange.start.round())} ر.س',
              '${_formatPrice(_priceRange.end.round())} ر.س',
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
            children: List.generate(6, (index) {
              final roomCount = index + 1;
              final isSelected = _rooms == roomCount;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _rooms = roomCount),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? gold : bgDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? gold : textMuted.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        '$roomCount',
                        style: GoogleFonts.cairo(
                          color: isSelected ? bgDark : textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Container(
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
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
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
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('لا توجد نتائج', style: GoogleFonts.cairo(color: textMuted, fontSize: 18)),
          const SizedBox(height: 8),
          Text('جرب تغيير معايير البحث', style: GoogleFonts.cairo(color: textMuted.withOpacity(0.6), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> property) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/property-detail', arguments: property),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textMuted.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              child: Image.network(
                property['image'],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 120,
                  height: 120,
                  color: cardDark,
                  child: const Icon(Icons.home, color: textMuted),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property['title'],
                            style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (property['trusted'])
                          const Icon(Icons.verified, size: 16, color: Color(0xFF059669)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: gold),
                        const SizedBox(width: 4),
                        Text(
                          '${property['district']}، ${property['city']}',
                          style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.king_bed, size: 14, color: textMuted),
                        const SizedBox(width: 3),
                        Text('${property['rooms']}', style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
                        const SizedBox(width: 10),
                        Icon(Icons.bathtub_outlined, size: 14, color: textMuted),
                        const SizedBox(width: 3),
                        Text('${property['baths']}', style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
                        const SizedBox(width: 10),
                        Icon(Icons.square_foot, size: 14, color: textMuted),
                        const SizedBox(width: 3),
                        Text('${property['area']} م²', style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatPrice(property['price'])} ر.س',
                      style: GoogleFonts.cairo(color: gold, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
