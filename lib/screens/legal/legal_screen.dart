import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

enum _LegalTab { privacy, terms }

@RoutePage()
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  _LegalTab _tab = _LegalTab.privacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          'السياسة القانونية',
          style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _buildIntro(),
                const SizedBox(height: 8),
                ...(_tab == _LegalTab.privacy
                    ? _privacySections()
                    : _termsSections()),
                const SizedBox(height: 16),
                _buildLastUpdated(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        children: [
          _buildTab(_LegalTab.privacy, 'سياسة الخصوصية'),
          _buildTab(_LegalTab.terms, 'الشروط والأحكام'),
        ],
      ),
    );
  }

  Widget _buildTab(_LegalTab tab, String label) {
    final selected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: selected ? Colors.white : textMuted,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x26E50914), Color(0x1FFF4757)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(Icons.gavel, color: primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'توثّق هذه الصفحة التزام منصة دارك وحيك بخصوصية بياناتك وشفافية ممارساتها، '
              'وبأن التعامل مع المنصة يخضع للشروط الموضحة أدناه.',
              style: GoogleFonts.cairo(color: textLight, fontSize: 13, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _privacySections() {
    return [
      _buildSection(
        '1. البيانات التي نجمعها',
        'عند استخدامك للمنصة قد نجمع: بيانات الحساب (الاسم، البريد الإلكتروني)، '
        'العقارات التي تحفظها في المفضلة، استعلاماتك عن العقارات والأسعار، '
        'وتفضيلات البحث. لا نجمع بيانات دفع لأن الخدمات الحالية مجانية.',
      ),
      _buildSection(
        '2. كيفية استخدام بياناتك',
        'تُستخدم بياناتك لتحسين تجربتك، وتقديم توصيات وأسعار عقارية مخصصة، '
        'وتشغيل الأدوات الذكية (تقدير السعر، نبض الحي، حاسبة العائد)، '
        'وتحسين أداء المنصة. لا نبيع بياناتك لأي طرف ثالث.',
      ),
      _buildSection(
        '3. التخزين والحماية',
        'نخزن بياناتك على خوادم آمنة مع تشفير عند النقل. المفضلة والتفضيلات '
        'المحلية تُحفظ على جهازك باستخدام التخزين الآمن للجهاز. نطبق إجراءات '
        'أمنية معقولة للحماية من الوصول غير المصرح به.',
      ),
      _buildSection(
        '4. مشاركة البيانات مع طرف ثالث',
        'لا نشارك بياناتك الشخصية إلا عند الحاجة: مزوّدو البنية التحتية السحابية '
        'لاستضافة الخدمة، ومزوّدو الخرائط لتشغيل الميزات الجغرافية. '
        'التقديرات والأسعار المعروضة استرشادية وليست استشارة استثمارية.',
      ),
      _buildSection(
        '5. حقوقك',
        'يحق لك طلب الاطلاع على بياناتك أو تصحيحها أو حذفها في أي وقت، '
        'كما يمكنك تعطيل حفظ التفضيلات المحلية من إعدادات جهازك. '
        'لأي استفسار راسلنا عبر support@darak-whayk.com.',
      ),
    ];
  }

  List<Widget> _termsSections() {
    return [
      _buildSection(
        '1. قبول الشروط',
        'باستخدامك لمنصة دارك وحيك فأنت توافق على هذه الشروط والأحكام. '
        'إذا كنت لا توافق على أي بند، يرجى التوقف عن استخدام المنصة.',
      ),
      _buildSection(
        '2. طبيعة الخدمة',
        'تقدم المنصة بيانات عقارية، وتقديرات أسعار، وتحليلات أحياء، وأدوات '
        'حساب تمويل استرشادية. جميع الأرقام المعروضة تقديرية ولا تشكل عرضاً '
        'أو استشارة قانونية أو مالية أو استثمارية ملزمة.',
      ),
      _buildSection(
        '3. مسؤولية المستخدم',
        'أنت مسؤول عن دقة المعلومات التي تدخلها عند إضافة العقارات، وعن '
        'التحقق المباشر من أي بيانات قبل اتخاذ قرارات الشراء أو الاستثمار. '
        'لا نتحمل مسؤولية الأضرار الناتجة عن الاعتماد على تقديرات المنصة.',
      ),
      _buildSection(
        '4. الملكية الفكرية',
        'جميع المحتوى، العلامات، التصاميم، والبرمجيات في المنصة ملك لمنصة '
        'دارك وحيك أو مرخّصة لها. يُمنع نسخها أو إعادة نشرها دون إذن كتابي.',
      ),
      _buildSection(
        '5. التعديلات وإنهاء الخدمة',
        'نحتفظ بحق تعديل هذه الشروط أو إيقاف أي جزء من الخدمة في أي وقت. '
        'ستُحدَّث هذه الصفحة عند أي تغيير، ويُعد استمرار الاستخدام موافقة '
        'على الشروط المحدثة.',
      ),
    ];
  }

  Widget _buildSection(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.cairo(color: textLight, fontSize: 13, height: 1.8),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Text(
      'آخر تحديث: أغسطس 2026',
      textAlign: TextAlign.center,
      style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
    );
  }
}
