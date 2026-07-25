import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color bgDark = Color(0xFF020617);
const Color gold = Color(0xFFD4AF37);
const Color cardDark = Color(0xFF0F172A);
const Color textLight = Color(0xFFF8FAFC);
const Color textMuted = Color(0xFF94A3B8);

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key});
  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  int _currentImage = 0;
  bool _isFavorite = false;

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final property = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgDark,
        body: CustomScrollView(
          slivers: [
            _buildImageGallery(property),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleAndPrice(property),
                    const SizedBox(height: 20),
                    _buildDetailsGrid(property),
                    const SizedBox(height: 20),
                    _buildFeaturesChips(),
                    const SizedBox(height: 20),
                    _buildDescription(),
                    const SizedBox(height: 20),
                    _buildAgentCard(property),
                    const SizedBox(height: 20),
                    _buildMapSection(),
                    const SizedBox(height: 20),
                    _buildSimilarProperties(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomActionBar(),
      ),
    );
  }

  Widget _buildImageGallery(Map<String, dynamic> property) {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: bgDark,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgDark.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward, color: textLight),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => setState(() => _isFavorite = !_isFavorite),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgDark.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : textLight,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgDark.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.share, color: textLight),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              itemCount: 5,
              onPageChanged: (i) => setState(() => _currentImage = i),
              itemBuilder: (context, index) {
                return Image.network(
                  property['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: cardDark,
                    child: const Icon(Icons.home, size: 60, color: textMuted),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentImage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentImage == index ? gold : textMuted.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgDark.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_currentImage + 1} / 5',
                  style: GoogleFonts.cairo(color: textLight, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndPrice(Map<String, dynamic> property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                property['title'],
                style: GoogleFonts.cairo(color: textLight, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: property['purpose'] == 'بيع' ? gold : const Color(0xFF1E40AF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                property['purpose'],
                style: GoogleFonts.cairo(
                  color: property['purpose'] == 'بيع' ? bgDark : textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, size: 18, color: gold),
            const SizedBox(width: 4),
            Text(
              '${property['district']}، ${property['city']}',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${_formatPrice(property['price'])} ${property['purpose'] == 'إيجار' ? 'ر.س/شهر' : 'ر.س'}',
          style: GoogleFonts.cairo(color: gold, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailsGrid(Map<String, dynamic> property) {
    final details = [
      {'icon': Icons.square_foot, 'label': 'المساحة', 'value': '${property['area']} م²'},
      {'icon': Icons.king_bed, 'label': 'الغرف', 'value': '${property['rooms']}'},
      {'icon': Icons.bathtub_outlined, 'label': 'الحمامات', 'value': '${property['baths']}'},
      {'icon': Icons.local_parking, 'label': 'المواقف', 'value': '2'},
      {'icon': Icons.front_hand, 'label': 'الواجهة', 'value': 'شرقية'},
      {'icon': Icons.calendar_today, 'label': 'سنة البناء', 'value': '2022'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تفاصيل العقار', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: details.length,
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: textMuted.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(details[index]['icon'] as IconData, color: gold, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    details[index]['value'] as String,
                    style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    details[index]['label'] as String,
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturesChips() {
    final features = ['مكيف مركزي', 'مطبخ مجهز', 'حديقة خاصة', 'مسبح', 'أمن 24/7', 'مصعد'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المميزات', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withOpacity(0.3)),
                ),
                child: Text(f, style: GoogleFonts.cairo(color: gold, fontSize: 13)),
              )).toList(),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الوصف', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          'فيلا فاخرة بتصميم عصري في حي النرجس بالرياض. تتميز بمساحات واسعة وتشطيبات راقية مع استخدام أجود المواد. تحتوي على 6 غرف نوم واسعة، وصالة استقبال كبيرة، ومطبخ مجهز بالكامل. الحديقة الخاصة توفر مساحة ممتعة للعائلات. تقع في موقع استراتيجي قريب من جميع الخدمات والمرافق الحيوية.',
          style: GoogleFonts.cairo(color: textMuted, fontSize: 15, height: 1.8),
        ),
      ],
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> property) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الوكيل العقاري', style: GoogleFonts.cairo(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: gold.withOpacity(0.2),
                child: Text(
                  (property['agent'] as String).substring(0, 1),
                  style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property['agent'],
                      style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('وكيل عقاري معتمد', style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
                  ],
                ),
              ),
              if (property['trusted'])
                Container(
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
                      Text('موثق', style: GoogleFonts.cairo(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAgentButton(
                  icon: Icons.phone,
                  label: 'اتصال',
                  color: const Color(0xFF059669),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAgentButton(
                  icon: Icons.chat,
                  label: 'واتساب',
                  color: const Color(0xFF25D366),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAgentButton(
                  icon: Icons.message,
                  label: 'رسالة',
                  color: const Color(0xFF1E40AF),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.cairo(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الموقع', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textMuted.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0xFF1A2744),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map, size: 50, color: textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'خريطة الموقع',
                          style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '24.7136° N, 46.6753° E',
                          style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_pin, color: bgDark, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarProperties() {
    final similar = [
      {'title': 'فيلا حي الملقا', 'price': 3200000, 'image': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800'},
      {'title': 'شقة حي الراكة', 'price': 650000, 'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800'},
      {'title': 'دوبلكس حي الياسمين', 'price': 1800000, 'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('عقارات مشابهة', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            itemBuilder: (context, index) {
              return Container(
                width: 220,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: textMuted.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Image.network(
                        similar[index]['image'] as String,
                        height: 90,
                        width: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          height: 90,
                          color: cardDark,
                          child: const Icon(Icons.home, color: textMuted),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            similar[index]['title'] as String,
                            style: GoogleFonts.cairo(color: textLight, fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatPrice(similar[index]['price'] as int)} ر.س',
                            style: GoogleFonts.cairo(color: gold, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardDark,
        border: Border(top: BorderSide(color: textMuted.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'تواصل مع الوكيل',
                    style: GoogleFonts.cairo(color: bgDark, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withOpacity(0.3)),
              ),
              child: Icon(Icons.phone, color: gold, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
