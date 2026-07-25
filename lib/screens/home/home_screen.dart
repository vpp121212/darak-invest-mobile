import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color bgDark = Color(0xFF020617);
const Color gold = Color(0xFFD4AF37);
const Color cardDark = Color(0xFF0F172A);
const Color textLight = Color(0xFFF8FAFC);
const Color textMuted = Color(0xFF94A3B8);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  int _currentNav = 0;
  final List<String> _tabs = ['بيع', 'إيجار', 'مزاد'];
  String? _selectedCity;
  String? _selectedType;

  final List<Map<String, dynamic>> _properties = const [
    {
      'id': 1,
      'title': 'فيلا فاخرة حي النرجس',
      'price': 2500000,
      'city': 'الرياض',
      'district': 'حي النرجس',
      'rooms': 6,
      'baths': 4,
      'area': 450,
      'image': 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
      'purpose': 'بيع',
      'type': 'فيلا',
      'trusted': true,
      'agent': 'أحمد العلي',
    },
    {
      'id': 2,
      'title': 'شقة أنيقة حي الملقا',
      'price': 850000,
      'city': 'الرياض',
      'district': 'حي الملقا',
      'rooms': 3,
      'baths': 2,
      'area': 180,
      'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      'purpose': 'بيع',
      'type': 'شقة',
      'trusted': true,
      'agent': 'محمد السالم',
    },
    {
      'id': 3,
      'title': 'دوبلكس حي الياسمين',
      'price': 12000,
      'city': 'جدة',
      'district': 'حي الياسمين',
      'rooms': 4,
      'baths': 3,
      'area': 250,
      'image': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      'purpose': 'إيجار',
      'type': 'دوبلكس',
      'trusted': false,
      'agent': 'فهد المطيري',
    },
    {
      'id': 4,
      'title': 'مكتب تجاري حي العليا',
      'price': 3500000,
      'city': 'الرياض',
      'district': 'حي العليا',
      'rooms': 8,
      'baths': 4,
      'area': 500,
      'image': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
      'purpose': 'بيع',
      'type': 'مكتب',
      'trusted': true,
      'agent': 'خالد الشمري',
    },
    {
      'id': 5,
      'title': 'استوديو حي الحمراء',
      'price': 4500,
      'city': 'جدة',
      'district': 'حي الحمراء',
      'rooms': 1,
      'baths': 1,
      'area': 65,
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
      'purpose': 'إيجار',
      'type': 'استوديو',
      'trusted': false,
      'agent': 'سعود الحربي',
    },
    {
      'id': 6,
      'title': 'فيلا عصرية حي الراكة',
      'price': 4200000,
      'city': 'الدمام',
      'district': 'حي الراكة',
      'rooms': 7,
      'baths': 5,
      'area': 600,
      'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
      'purpose': 'بيع',
      'type': 'فيلا',
      'trusted': true,
      'agent': 'عبدالله القحطاني',
    },
  ];

  final List<Map<String, String>> _sections = const [
    {'icon': '🏠', 'label': 'بيع'},
    {'icon': '🔑', 'label': 'إيجار'},
    {'icon': '🏢', 'label': 'مكاتب'},
    {'icon': '🤝', 'label': 'وسطاء'},
    {'icon': '🏷️', 'label': 'مزادات'},
  ];

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
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
            'دارك وحيك',
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: gold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: textMuted),
              onPressed: () {},
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: gold,
          backgroundColor: cardDark,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 12),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildFilterRow(),
              const SizedBox(height: 20),
              _buildSectionsBar(),
              const SizedBox(height: 20),
              _buildPropertiesHeader(),
              const SizedBox(height: 12),
              ..._properties.map((p) => _buildPropertyCard(p)),
              const SizedBox(height: 20),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: textMuted, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ابحث عن عقارك المثالي...',
                          style: GoogleFonts.cairo(color: textMuted, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _currentTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentTab = index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? gold : cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? gold : textMuted.withOpacity(0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _tabs[index],
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
        ),
      ],
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
            onTap: () => _showCityPicker(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.home_outlined,
            label: _selectedType ?? 'النوع',
            onTap: () => _showTypePicker(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.attach_money,
            label: 'نطاق السعر',
            onTap: () {},
          ),
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
          border: Border.all(color: textMuted.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: gold),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.cairo(color: textLight, fontSize: 13)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsBar() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          return Container(
            width: 72,
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withOpacity(0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_sections[index]['icon']!, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  _sections[index]['label']!,
                  style: GoogleFonts.cairo(color: textLight, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPropertiesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'أحدث العقارات',
          style: GoogleFonts.cairo(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {},
          child: Text('عرض الكل', style: GoogleFonts.cairo(color: gold, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/property-detail', arguments: property);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textMuted.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    property['image'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 180,
                      color: cardDark,
                      child: const Icon(Icons.home, size: 50, color: textMuted),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: property['purpose'] == 'بيع' ? gold : const Color(0xFF1E40AF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      property['purpose'],
                      style: GoogleFonts.cairo(
                        color: property['purpose'] == 'بيع' ? bgDark : textLight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (property['trusted'])
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'موثق',
                            style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['title'],
                    style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: gold),
                      const SizedBox(width: 4),
                      Text(
                        '${property['district']}، ${property['city']}',
                        style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSpec(Icons.king_bed, '${property['rooms']} غرف'),
                      const SizedBox(width: 14),
                      _buildSpec(Icons.bathtub_outlined, '${property['baths']} حمام'),
                      const SizedBox(width: 14),
                      _buildSpec(Icons.square_foot, '${property['area']} م²'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatPrice(property['price'])} ${property['purpose'] == 'إيجار' ? 'ر.س/شهر' : 'ر.س'}',
                        style: GoogleFonts.cairo(color: gold, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'الوكيل: ${property['agent']}',
                        style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpec(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textMuted),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
      ],
    );
  }

  void _showCityPicker() {
    final cities = ['الرياض', 'جدة', 'الدمام', 'مكة', 'المدينة', 'الظهران', 'الأحساء'];
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
              child: Text('اختر المدينة', style: GoogleFonts.cairo(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...cities.map((city) => ListTile(
                  title: Text(city, style: GoogleFonts.cairo(color: textLight)),
                  trailing: _selectedCity == city ? Icon(Icons.check, color: gold) : null,
                  onTap: () {
                    setState(() => _selectedCity = city);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTypePicker() {
    final types = ['فيلا', 'شقة', 'دوبلكس', 'مكتب', 'استوديو', 'أرض', 'عمارة'];
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
              child: Text('اختر النوع', style: GoogleFonts.cairo(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...types.map((type) => ListTile(
                  title: Text(type, style: GoogleFonts.cairo(color: textLight)),
                  trailing: _selectedType == type ? Icon(Icons.check, color: gold) : null,
                  onTap: () {
                    setState(() => _selectedType = type);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home, 'label': 'الرئيسية'},
      {'icon': Icons.search, 'label': 'بحث'},
      {'icon': Icons.add_circle_outline, 'label': 'إضافة'},
      {'icon': Icons.dashboard_outlined, 'label': 'لوحة التحكم'},
      {'icon': Icons.person_outline, 'label': 'حسابي'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        border: Border(top: BorderSide(color: textMuted.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isActive = _currentNav == index;
              return GestureDetector(
                onTap: () => setState(() => _currentNav = index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[index]['icon'] as IconData,
                      color: isActive ? gold : textMuted,
                      size: index == 2 ? 36 : 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index]['label'] as String,
                      style: GoogleFonts.cairo(
                        color: isActive ? gold : textMuted,
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
