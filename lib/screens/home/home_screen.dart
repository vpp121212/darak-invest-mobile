import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../models/property.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/property_card.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _purpose = 'الكل';
  String? _selectedCity;
  String? _selectedType;
  final List<String> _purposes = ['الكل', 'بيع', 'إيجار'];
  static const _cities = ['الرياض', 'جدة', 'مكة', 'الدمام', 'الخبر', 'حائل'];
  static const _types = ['فيلا', 'شقة', 'دوبلكس', 'مكتب', 'استوديو', 'أرض', 'عمارة'];

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'دارك وحيك',
          style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: gold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: textMuted),
            onPressed: () => _showComingSoon('الإشعارات'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: gold,
        backgroundColor: cardDark,
        onRefresh: () => ref.read(propertiesProvider.notifier).load(),
        child: _buildBody(catalogue),
      ),
    );
  }

  Widget _buildBody(PropertyCatalogueState catalogue) {
    if (catalogue.isLoading) return const _HomeSkeleton();
    if (catalogue.error != null && catalogue.properties.isEmpty) {
      return _HomeError(
        message: catalogue.error!,
        onRetry: () => ref.read(propertiesProvider.notifier).load(),
      );
    }
    final filtered = _applyFilters(catalogue.properties);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 12),
        if (catalogue.error != null) ...[
          _OfflineBanner(error: catalogue.error!),
          const SizedBox(height: 12),
        ],
        _buildSearchBar(),
        const SizedBox(height: 12),
        _buildPurposeTabs(),
        const SizedBox(height: 16),
        _buildFilterRow(),
        const SizedBox(height: 20),
        _buildAiToolsRow(),
        const SizedBox(height: 20),
        _buildHeader('أحدث العقارات', catalogue.properties.length),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const _EmptyState()
        else
          ...filtered.map((p) => PropertyCard(
                property: p,
                onTap: () => _openDetail(p),
              )),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Property> _applyFilters(List<Property> all) {
    return all.where((p) {
      if (_purpose != 'الكل' && p.purpose != _purpose) return false;
      if (_selectedCity != null && p.city != _selectedCity) return false;
      if (_selectedType != null && p.type != _selectedType) return false;
      return true;
    }).toList();
  }

  void _openDetail(Property property) {
    context.pushRoute(PropertyDetailRoute(property: property));
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — قريباً', style: GoogleFonts.cairo())),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => context.pushRoute(const SearchRoute()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: textMuted, size: 22),
            const SizedBox(width: 10),
            Text('ابحث عن عقارك المثالي...', style: GoogleFonts.cairo(color: textMuted, fontSize: 15)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('بحث', style: GoogleFonts.cairo(color: gold, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeTabs() {
    return Row(
      children: List.generate(_purposes.length, (index) {
        final purpose = _purposes[index];
        final isSelected = _purpose == purpose;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _purpose = purpose),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? gold : cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? gold : textMuted.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Text(
                  purpose,
                  style: GoogleFonts.cairo(
                    color: isSelected ? bgDark : textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            icon: Icons.location_city,
            label: _selectedCity ?? 'المدينة',
            onTap: () => _showPicker('اختر المدينة', _cities, (v) => setState(() => _selectedCity = v)),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.home_outlined,
            label: _selectedType ?? 'النوع',
            onTap: () => _showPicker('اختر النوع', _types, (v) => setState(() => _selectedType = v)),
          ),
          if (_selectedCity != null || _selectedType != null) ...[
            const SizedBox(width: 8),
            _buildClearFiltersChip(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textMuted.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: gold),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.cairo(color: textLight, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildClearFiltersChip() {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCity = null;
        _selectedType = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: Text('مسح الفلاتر', style: GoogleFonts.cairo(color: Colors.red, fontSize: 13)),
      ),
    );
  }

  void _showPicker(String title, List<String> items, ValueChanged<String> onSelected) {
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
            child: Text(title, style: GoogleFonts.cairo(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...items.map((item) => ListTile(
                title: Text(item, style: GoogleFonts.cairo(color: textLight)),
                trailing: _selectedCity == item || _selectedType == item
                    ? const Icon(Icons.check, color: gold)
                    : null,
                onTap: () {
                  onSelected(item);
                  context.pop();
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAiToolsRow() {
    final tools = <(String, IconData, VoidCallback)>[
      ('تقدير السعر', Icons.calculate_outlined, () => context.pushRoute(EstimateRoute())),
      ('نبض الحي', Icons.location_city, () => context.pushRoute(PulseRoute())),
      ('حاسبة ROI', Icons.trending_up, () => context.pushRoute(RoiRoute())),
    ];
    return Row(
      children: tools.map((tool) {
        return Expanded(
          child: GestureDetector(
            onTap: tool.$3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Icon(tool.$2, color: gold, size: 24),
                  const SizedBox(height: 8),
                  Text(tool.$1, style: GoogleFonts.cairo(color: textLight, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.cairo(color: textLight, fontSize: 20, fontWeight: FontWeight.bold)),
        Text('$count عقار', style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 320,
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: CircularProgressIndicator(color: gold.withValues(alpha: 0.4), strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final String error;

  const _OfflineBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تعذّر تحديث البيانات — تعرض نسخة محفوظة/تجريبية',
              style: GoogleFonts.cairo(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HomeError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off, size: 60, color: textMuted),
        const SizedBox(height: 16),
        Text(
          'تعذّر تحميل العقارات',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: bgDark, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 60, color: textMuted),
          const SizedBox(height: 12),
          Text('لا توجد عقارات مطابقة', style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('جرّب تغيير الفلاتر', style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
