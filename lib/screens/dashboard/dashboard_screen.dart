import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color bgDark = Color(0xFF020617);
const Color gold = Color(0xFFD4AF37);
const Color cardDark = Color(0xFF0F172A);
const Color textLight = Color(0xFFF8FAFC);
const Color textMuted = Color(0xFF94A3B8);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userRole = 'advertiser';
  int _currentStep = 0;

  final Map<String, List<Map<String, dynamic>>> _kpiData = {
    'admin': [
      {'title': 'إجمالي المستخدمين', 'value': '1,247', 'icon': Icons.people_outline, 'color': Color(0xFF3B82F6)},
      {'title': 'العقارات المنشورة', 'value': '3,891', 'icon': Icons.home_outlined, 'color': Color(0xFF10B981)},
      {'title': 'المكاتب المسجلة', 'value': '156', 'icon': Icons.business_outlined, 'color': gold},
      {'title': 'الإيرادات', 'value': '89,500 ر.س', 'icon': Icons.attach_money, 'color': Color(0xFF8B5CF6)},
    ],
    'advertiser': [
      {'title': 'عقاراتي', 'value': '12', 'icon': Icons.home_outlined, 'color': gold},
      {'title': 'المشاهدات', 'value': '5,670', 'icon': Icons.visibility_outlined, 'color': Color(0xFF3B82F6)},
      {'title': 'الرسائل', 'value': '23', 'icon': Icons.mail_outline, 'color': Color(0xFF10B981)},
      {'title': 'الإشعارات', 'value': '5', 'icon': Icons.notifications_outlined, 'color': Color(0xFFF59E0B)},
    ],
    'agent': [
      {'title': 'العملاء', 'value': '48', 'icon': Icons.people_outline, 'color': Color(0xFF3B82F6)},
      {'title': 'الصفقات', 'value': '8', 'icon': Icons.handshake_outlined, 'color': gold},
      {'title': 'العقارات النشطة', 'value': '15', 'icon': Icons.home_outlined, 'color': Color(0xFF10B981)},
      {'title': 'العمولات', 'value': '23,000 ر.س', 'icon': Icons.attach_money, 'color': Color(0xFF8B5CF6)},
    ],
    'office': [
      {'title': 'العملاء', 'value': '120', 'icon': Icons.people_outline, 'color': Color(0xFF3B82F6)},
      {'title': 'الموظفين', 'value': '8', 'icon': Icons.group_outlined, 'color': Color(0xFF10B981)},
      {'title': 'العقارات', 'value': '45', 'icon': Icons.home_outlined, 'color': gold},
      {'title': 'الإيرادات الشهرية', 'value': '156,000 ر.س', 'icon': Icons.attach_money, 'color': Color(0xFF8B5CF6)},
    ],
    'browser': [
      {'title': 'المفضلة', 'value': '15', 'icon': Icons.favorite_outline, 'color': Colors.red},
      {'title': 'المحفوظات', 'value': '32', 'icon': Icons.bookmark_outline, 'color': gold},
      {'title': 'عمليات البحث', 'value': '8', 'icon': Icons.search, 'color': Color(0xFF3B82F6)},
      {'title': 'آخر الزيارات', 'value': '23', 'icon': Icons.history, 'color': Color(0xFF10B981)},
    ],
  };

  final List<Map<String, dynamic>> _myProperties = const [
    {'title': 'فيلا حي النرجس', 'status': 'منشور', 'statusColor': Color(0xFF10B981), 'views': 1240, 'price': 2500000},
    {'title': 'شقة حي الملقا', 'status': 'قيد المراجعة', 'statusColor': Color(0xFFF59E0B), 'views': 0, 'price': 850000},
    {'title': 'مكتب حي العليا', 'status': 'مرفوض', 'statusColor': Colors.red, 'views': 0, 'price': 3500000},
  ];

  final List<Map<String, dynamic>> _users = const [
    {'name': 'أحمد العلي', 'role': 'معلن', 'status': 'مفعل', 'verified': true},
    {'name': 'محمد السالم', 'role': 'وسيط', 'status': 'معلق', 'verified': false},
    {'name': 'فهد المطيري', 'role': 'مكتب', 'status': 'مفعل', 'verified': true},
    {'name': 'سعود الحربي', 'role': 'متصفح', 'status': 'مفعل', 'verified': false},
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
            _getRoleTitle(),
            style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: textMuted),
              onPressed: () {},
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRoleSwitcher(),
            const SizedBox(height: 20),
            _buildKPICards(),
            const SizedBox(height: 24),
            if (_userRole == 'admin') _buildUserManagement(),
            if (_userRole != 'admin' && _userRole != 'browser') ...[
              _buildPropertyHeader(),
              const SizedBox(height: 12),
              ..._myProperties.map((p) => _buildPropertyItem(p)),
              const SizedBox(height: 24),
              _buildAddPropertyButton(),
            ],
            if (_userRole == 'browser') _buildBrowserContent(),
          ],
        ),
      ),
    );
  }

  String _getRoleTitle() {
    switch (_userRole) {
      case 'admin':
        return 'لوحة التحكم - المدير';
      case 'advertiser':
        return 'لوحة التحكم - المعلن';
      case 'agent':
        return 'لوحة التحكم - الوسيط';
      case 'office':
        return 'لوحة التحكم - المكتب';
      default:
        return 'حسابي';
    }
  }

  Widget _buildRoleSwitcher() {
    final roles = [
      {'key': 'admin', 'label': 'مدير', 'icon': Icons.admin_panel_settings},
      {'key': 'advertiser', 'label': 'معلن', 'icon': Icons.campaign},
      {'key': 'agent', 'label': 'وسيط', 'icon': Icons.handshake},
      {'key': 'office', 'label': 'مكتب', 'icon': Icons.business},
      {'key': 'browser', 'label': 'متصفح', 'icon': Icons.person},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: roles.length,
        itemBuilder: (context, index) {
          final role = roles[index];
          final isSelected = _userRole == role['key'];
          return GestureDetector(
            onTap: () => setState(() => _userRole = role['key'] as String),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? gold : cardDark,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: isSelected ? gold : textMuted.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(role['icon'] as IconData, size: 18, color: isSelected ? bgDark : textMuted),
                  const SizedBox(width: 6),
                  Text(
                    role['label'] as String,
                    style: GoogleFonts.cairo(
                      color: isSelected ? bgDark : textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPICards() {
    final kpis = _kpiData[_userRole] ?? [];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textMuted.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (kpi['color'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(kpi['icon'] as IconData, color: kpi['color'] as Color, size: 20),
                  ),
                  const Spacer(),
                  Text(kpi['title'], style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                kpi['value'],
                style: GoogleFonts.cairo(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPropertyHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('عقاراتي', style: GoogleFonts.cairo(color: textLight, fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton.icon(
          onPressed: () => _showAddPropertyForm(),
          icon: Icon(Icons.add, color: gold, size: 20),
          label: Text('إضافة عقار', style: GoogleFonts.cairo(color: gold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildPropertyItem(Map<String, dynamic> property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textMuted.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home, color: gold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property['title'], style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (property['statusColor'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        property['status'],
                        style: GoogleFonts.cairo(color: property['statusColor'] as Color, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.visibility_outlined, size: 14, color: textMuted),
                    const SizedBox(width: 3),
                    Text('${property['views']}', style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatPrice(property['price'])} ر.س',
                style: GoogleFonts.cairo(color: gold, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                onSelected: (val) {},
                color: cardDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                icon: Icon(Icons.more_vert, color: textMuted, size: 20),
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text('تعديل', style: GoogleFonts.cairo(color: textLight, fontSize: 13))),
                  PopupMenuItem(value: 'delete', child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red, fontSize: 13))),
                  PopupMenuItem(value: 'views', child: Text('المشاهدات', style: GoogleFonts.cairo(color: textLight, fontSize: 13))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPropertyButton() {
    return GestureDetector(
      onTap: () => _showAddPropertyForm(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: gold.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: gold, size: 22),
            const SizedBox(width: 8),
            Text('إضافة عقار جديد', style: GoogleFonts.cairo(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إدارة المستخدمين', style: GoogleFonts.cairo(color: textLight, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._users.map((user) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: textMuted.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: gold.withOpacity(0.2),
                    child: Text(
                      user['name'].toString().substring(0, 1),
                      style: GoogleFonts.cairo(color: gold, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(user['name'], style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold)),
                            if (user['verified']) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, size: 14, color: Color(0xFF059669)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(user['role'], style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: user['status'] == 'مفعل' ? const Color(0xFF059669).withOpacity(0.15) : const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user['status'],
                      style: GoogleFonts.cairo(
                        color: user['status'] == 'مactivate' ? const Color(0xFF059669) : const Color(0xFFF59E0B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {},
                    color: cardDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    icon: Icon(Icons.more_vert, color: textMuted, size: 18),
                    itemBuilder: (ctx) => [
                      PopupMenuItem(value: 'activate', child: Text('تفعيل', style: GoogleFonts.cairo(color: textLight, fontSize: 12))),
                      PopupMenuItem(value: 'suspend', child: Text(' تعليق', style: GoogleFonts.cairo(color: textMuted, fontSize: 12))),
                      PopupMenuItem(value: 'delete', child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red, fontSize: 12))),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildBrowserContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('حسابي', style: GoogleFonts.cairo(color: textLight, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildProfileMenuItem(Icons.person_outline, 'معلومات الحساب'),
        _buildProfileMenuItem(Icons.favorite_outline, 'العقارات المفضلة'),
        _buildProfileMenuItem(Icons.bookmark_outline, 'المحفوظات'),
        _buildProfileMenuItem(Icons.history, 'سجل المشاهدات'),
        _buildProfileMenuItem(Icons.settings_outlined, 'الإعدادات'),
        _buildProfileMenuItem(Icons.help_outline, 'المساعدة والدعم'),
        _buildProfileMenuItem(Icons.logout, 'تسجيل الخروج', isLogout: true),
      ],
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String label, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : gold, size: 22),
        title: Text(label, style: GoogleFonts.cairo(color: isLogout ? Colors.red : textLight, fontSize: 15)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: textMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {},
      ),
    );
  }

  void _showAddPropertyForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: textMuted, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إضافة عقار جديد', style: GoogleFonts.cairo(color: gold, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStepIndicator(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _currentStep == 0
                        ? _buildStep1()
                        : _currentStep == 1
                            ? _buildStep2()
                            : _buildStep3(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => _currentStep--),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: bgDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: textMuted.withOpacity(0.2)),
                              ),
                              child: Center(
                                child: Text('السابق', style: GoogleFonts.cairo(color: textMuted, fontSize: 15)),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_currentStep < 2) {
                              setModalState(() => _currentStep++);
                            } else {
                              Navigator.pop(ctx);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(14)),
                            child: Center(
                              child: Text(
                                _currentStep == 2 ? 'نشر العقار' : 'التالي',
                                style: GoogleFonts.cairo(color: bgDark, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final labels = ['المعلومات', 'الصور', 'الموقع'];
        final isActive = _currentStep >= index;
        return Expanded(
          child: Row(
            children: [
              if (index > 0) Expanded(child: Container(height: 2, color: isActive ? gold : textMuted.withOpacity(0.3))),
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive ? gold : cardDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: isActive ? gold : textMuted.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: _currentStep > index
                          ? const Icon(Icons.check, size: 16, color: bgDark)
                          : Text('${index + 1}', style: GoogleFonts.cairo(color: isActive ? bgDark : textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[index], style: GoogleFonts.cairo(color: isActive ? gold : textMuted, fontSize: 10)),
                ],
              ),
              if (index < 2) Expanded(child: Container(height: 2, color: _currentStep > index ? gold : textMuted.withOpacity(0.3))),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStep1() {
    final _fieldDecoration = (String hint, IconData icon) => InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(color: textMuted),
          prefixIcon: Icon(icon, color: textMuted),
          filled: true,
          fillColor: bgDark,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: textMuted.withOpacity(0.2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: textMuted.withOpacity(0.2))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gold)),
        );

    return ListView(
      children: [
        TextFormField(style: GoogleFonts.cairo(color: textLight), decoration: _fieldDecoration('عنوان العقار', Icons.title)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextFormField(style: GoogleFonts.cairo(color: textLight), decoration: _fieldDecoration('السعر', Icons.attach_money))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(style: GoogleFonts.cairo(color: textLight), decoration: _fieldDecoration('المساحة (م²)', Icons.square_foot))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextFormField(style: GoogleFonts.cairo(color: textLight), decoration: _fieldDecoration('الغرف', Icons.king_bed))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(style: GoogleFonts.cairo(color: textLight), decoration: _fieldDecoration('الحمامات', Icons.bathtub_outlined))),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          style: GoogleFonts.cairo(color: textLight),
          maxLines: 4,
          decoration: _fieldDecoration('الوصف التفصيلي', Icons.description_outlined),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: textMuted.withOpacity(0.2), style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 50, color: textMuted.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text('اضغط لرفع الصور', style: GoogleFonts.cairo(color: textMuted, fontSize: 15)),
                const SizedBox(height: 4),
                Text('الحد الأقصى 10 صور', style: GoogleFonts.cairo(color: textMuted.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 50, color: textMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text('حدد الموقع على الخريطة', style: GoogleFonts.cairo(color: textMuted, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('اضغط على الخريطة لتحديد الموقع', style: GoogleFonts.cairo(color: textMuted.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gold.withOpacity(0.3)),
                    ),
                    child: Text('تحديد الموقع الحالي', style: GoogleFonts.cairo(color: gold, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
