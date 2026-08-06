import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/app_exception.dart';
import '../../providers/properties_provider.dart';
import '../../providers/tab_provider.dart';
import '../../services/api_service.dart';
import '../../services/local_properties_store.dart';
import '../../theme/app_theme.dart';

/// إضافة عقار جديد (نشر إعلان).
///
/// يكمل دورة البيانات «إدخال المالك ← عرض المستخدم»: يدخل المالك بيانات
/// العقار إضافة إلى روابط الجولة 360° (صور الغرف) وملفات بيت الدمية (.glb).
/// عند نجاح الاتصال يُنشر على الخادم، وإلا يُحفظ محلياً ويظهر في القائمة.
class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();
  final _bathsCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'الرياض');
  final _districtCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imagesCtrl = TextEditingController();
  final _panoCtrl = TextEditingController();
  final _panosCtrl = TextEditingController();
  final _model3dCtrl = TextEditingController();
  final _modelsCtrl = TextEditingController();

  String _type = 'شقة';
  String _purpose = 'بيع';
  bool _saving = false;

  static const _types = ['شقة', 'فيلا', 'دوبلكس', 'مكتب', 'استوديو', 'أرض', 'عمارة', 'محل'];
  static const _purposes = ['بيع', 'إيجار', 'رهن'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _areaCtrl.dispose();
    _roomsCtrl.dispose();
    _bathsCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _descCtrl.dispose();
    _imagesCtrl.dispose();
    _panoCtrl.dispose();
    _panosCtrl.dispose();
    _model3dCtrl.dispose();
    _modelsCtrl.dispose();
    super.dispose();
  }

  static List<String> _urls(String raw) {
    // الروابط يجب أن تكون http(s) حرفياً وخالية من أي محارف هجومية
    // (اقتباسات/أقواس/مسافات) حتى لا تُستخدم لحقن HTML/JS في العارضين.
    final dangerous = RegExp(r'''[\s"'`<>]''');
    return raw
        .split(RegExp(r'[\s,;]+'))
        .map((e) => e.trim())
        .where((e) =>
            RegExp(r'^https?://', caseSensitive: false).hasMatch(e) &&
            !dangerous.hasMatch(e))
        .toList();
  }

  static String _firstUrl(String raw) {
    final urls = _urls(raw);
    return urls.isEmpty ? '' : urls.first;
  }

  String? _validateUrls(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _urls(value).isEmpty ? 'أدخل رابطاً صحيحاً يبدأ بـ https://' : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'type': _type,
      'purpose': _purpose,
      'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
      'area': double.tryParse(_areaCtrl.text.trim()) ?? 0,
      'rooms': int.tryParse(_roomsCtrl.text.trim()) ?? 0,
      'baths': int.tryParse(_bathsCtrl.text.trim()) ?? 0,
      'city': _cityCtrl.text.trim().isEmpty ? 'الرياض' : _cityCtrl.text.trim(),
      'district': _districtCtrl.text.trim().isEmpty
          ? _cityCtrl.text.trim().isEmpty
              ? 'الرياض'
              : _cityCtrl.text.trim()
          : _districtCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'year': DateTime.now().year,
      'age': 0,
      'facing': 'شمالي',
      'features': const <String>[],
      'images': _urls(_imagesCtrl.text),
      'panoramicImage': _firstUrl(_panoCtrl.text),
      'panoramicImages': _urls(_panosCtrl.text),
      'model3dUrl': _firstUrl(_model3dCtrl.text),
      'model3dUrls': _urls(_modelsCtrl.text),
      'trust': 100,
      'isDemo': false,
    };

    var published = false;
    try {
      await ApiService.createProperty(body);
      published = true;
    } catch (e) {
      await LocalPropertiesStore.saveLocalProperty(body);
      if (!mounted) return;
      final message = e is AppException ? ' (${e.message})' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cardDark,
          content: Text(
            'تعذّر الاتصال بالخادم$message — حُفظ العقار محلياً',
            style: GoogleFonts.cairo(color: textLight),
          ),
        ),
      );
    }

    if (!mounted) return;
    if (published) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: green,
          content: Text(
            'تم نشر الإعلان بنجاح ✓',
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    ref.read(propertiesProvider.notifier).load();
    ref.read(activeTabProvider.notifier).state = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          'إضافة عقار',
          style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('بيانات العقار', Icons.home_work_outlined),
            _buildTextForm(
              _titleCtrl,
              label: 'عنوان الإعلان *',
              hint: 'مثال: فيلا فاخرة في الياسمين',
              icon: Icons.title,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'أدخل عنوان الإعلان' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDropdown('النوع', _types, _type, (v) => setState(() => _type = v))),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('الغرض', _purposes, _purpose, (v) => setState(() => _purpose = v))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextForm(
                    _priceCtrl,
                    label: 'السعر (ر.س)',
                    hint: 'مثال: 2450000',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextForm(
                    _areaCtrl,
                    label: 'المساحة (م²)',
                    hint: 'مثال: 420',
                    icon: Icons.square_foot,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextForm(
                    _roomsCtrl,
                    label: 'عدد الغرف',
                    hint: 'مثال: 5',
                    icon: Icons.king_bed_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextForm(
                    _bathsCtrl,
                    label: 'عدد الحمامات',
                    hint: 'مثال: 4',
                    icon: Icons.bathtub_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextForm(
                    _cityCtrl,
                    label: 'المدينة',
                    icon: Icons.location_city,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextForm(
                    _districtCtrl,
                    label: 'الحي',
                    hint: 'مثال: الياسمين',
                    icon: Icons.map_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextForm(
              _descCtrl,
              label: 'وصف العقار',
              hint: 'تفاصيل إضافية عن العقار...',
              icon: Icons.notes,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            _sectionHeader('الصور والجولة 360°', Icons.threesixty),
            _buildInfoRow(
              'ألصق روابط الصور البانورامية (داخلية 2:1) لتفعيل جولة 360° ودخول المنزل بين الغرف.',
            ),
            const SizedBox(height: 12),
            _buildTextForm(
              _imagesCtrl,
              label: 'روابط الصور (مفصولة بفواصل)',
              hint: 'https://.../img1.jpg, https://.../img2.jpg',
              icon: Icons.image_outlined,
              validator: _validateUrls,
            ),
            const SizedBox(height: 12),
            _buildTextForm(
              _panoCtrl,
              label: 'رابط الصورة البانورامية الرئيسية (360)',
              hint: 'https://.../pano.jpg',
              icon: Icons.threesixty,
              validator: _validateUrls,
            ),
            const SizedBox(height: 12),
            _buildTextForm(
              _panosCtrl,
              label: 'روابط الغرف الأخرى (360، مفصولة بفواصل)',
              hint: 'https://.../room1.jpg, https://.../room2.jpg',
              icon: Icons.meeting_room_outlined,
              maxLines: 2,
              validator: _validateUrls,
            ),
            const SizedBox(height: 24),
            _sectionHeader('بيت الدمية ثلاثي الأبعاد', Icons.view_in_ar),
            _buildInfoRow(
              'ألصق روابط ملفات النماذج (.glb) لتفعيل عرض بيت الدمية التفاعلي بأوضاعه الثلاثة.',
            ),
            const SizedBox(height: 12),
            _buildTextForm(
              _model3dCtrl,
              label: 'رابط النموذج الرئيسي (.glb)',
              hint: 'https://.../villa.glb',
              icon: Icons.view_in_ar,
              validator: _validateUrls,
            ),
            const SizedBox(height: 12),
            _buildTextForm(
              _modelsCtrl,
              label: 'روابط نماذج إضافية (مفصولة بفواصل)',
              hint: 'https://.../room.glb, https://.../chair.glb',
              icon: Icons.widgets_outlined,
              maxLines: 2,
              validator: _validateUrls,
            ),
            const SizedBox(height: 28),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(color: textLight, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: gold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(color: textMuted, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> options,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return GestureDetector(
      onTap: () => _showPicker(label, options, value, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: textMuted.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.arrow_drop_down, color: gold, size: 22),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(
    String label,
    List<String> options,
    String value,
    ValueChanged<String> onChanged,
  ) {
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
            child: Text(label, style: GoogleFonts.cairo(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...options.map((item) => ListTile(
                title: Text(item, style: GoogleFonts.cairo(color: textLight)),
                trailing: value == item ? const Icon(Icons.check, color: gold) : null,
                onTap: () {
                  onChanged(item);
                  context.pop();
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTextForm(
    TextEditingController controller, {
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      validator: validator,
      style: GoogleFonts.cairo(color: textLight, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: textMuted, fontSize: 12),
        labelStyle: GoogleFonts.cairo(color: gold, fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, color: textMuted, size: 20) : null,
        filled: true,
        fillColor: cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textMuted.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: textMuted.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.6)),
        ),
        errorStyle: GoogleFonts.cairo(color: Colors.red, fontSize: 12),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _saving ? null : _submit,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: gold,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'نشر الإعلان',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
