// بيانات المدن والأحياء الفعلية المستخدمة في بحث وإضافة العقارات.
// الرياض مقسمة إلى أربع جهات (شمال/شرق/غرب/جنوب) مع أحيائها الفعلية،
// وبقية المدن الرئيسية مرفقة بأشهر أحيائها.

class CityDirection {
  final String name;
  final List<String> neighborhoods;

  const CityDirection({required this.name, required this.neighborhoods});
}

class CityData {
  final String name;
  final List<CityDirection> directions;

  const CityData({required this.name, this.directions = const []});

  /// كل الأحياء في المدينة بغض النظر عن الجهة.
  List<String> get allNeighborhoods {
    return [for (final d in directions) ...d.neighborhoods];
  }
}

const List<CityData> kCities = [
  CityData(
    name: 'الرياض',
    directions: [
      CityDirection(name: 'شمال الرياض', neighborhoods: [
        'الملقا',
        'النرجس',
        'الياسمين',
        'حطين',
        'الورود',
        'الرياض',
        'النخيل',
        'محيذيف',
        'العرض',
        'المصيف',
        'النخيل الغربي',
        'الرحاب',
        'الرمال',
        'عارض',
        'القيروان',
        'بنان',
        'الخزامى',
        'الإزدهار',
        'الواحة',
        'مرسيلا',
      ]),
      CityDirection(name: 'شرق الرياض', neighborhoods: [
        'الملز',
        'الربوة',
        'القدس',
        'النعيم',
        'أحد',
        'الروضة',
        'السلام',
        'الجنادرية',
        'الحمراء',
        'المناخ',
        'النسيم',
        'الملها',
        'الجنوبية',
        'قرطبة',
        'الوادي',
        'الندى',
        'غرناطة',
        'إشبيلية',
        'الزهراء',
        'الروابي',
      ]),
      CityDirection(name: 'غرب الرياض', neighborhoods: [
        'العريجاء',
        'العارض',
        'شميسي',
        'البديعة',
        'الدريهمية',
        'الشفاء',
        'السويدي',
        'الحائر',
        'لبن',
        'الفيصلية',
        'طويق',
        'المدينة',
        'الخالدية',
        'العزة',
        'الروضة',
        'الملقا الغربية',
        'الأصفر',
        'بدر',
        'الرانوناء',
        'القبانية',
      ]),
      CityDirection(name: 'جنوب الرياض', neighborhoods: [
        'الدفاع',
        'منفوحة',
        'عتيقة',
        'الحلة',
        'السلام',
        'الدرعية',
        'السلي',
        'الحزم',
        'المصانع',
        'الشعلان',
        'الملك فهد',
        'اليرموك',
        'الصحابة',
        'النزلة',
        'المنصورة',
        'الجوهرة',
        'الزهرة',
        'الفواز',
        'السلامية',
        'الجبل',
      ]),
    ],
  ),
  CityData(
    name: 'جدة',
    directions: [
      CityDirection(name: 'شمال جدة', neighborhoods: [
        'الأندلس',
        'المنار',
        'المروة',
        'النهضة',
        'النعيم',
        'أبحر الشمالية',
        'الشميسي',
        'الواجهة البحرية',
        'الحمدانية',
        'الصالحية',
        'الأجواد',
        'الأبراج',
        'النسيم',
        'الفيحاء',
        'الربوة',
      ]),
      CityDirection(name: 'وسط جدة', neighborhoods: [
        'البلد',
        'الروضة',
        'الزهراء',
        'بترومين',
        'الهنداوية',
        'الصفا',
        'النخيل',
        'المرجان',
        'الشاطئ',
        'الجامعة',
        'الحمراء',
        'بغداد',
        'الكندرة',
        'السلامة',
      ]),
      CityDirection(name: 'جنوب جدة', neighborhoods: [
        'المنصورية',
        'الجوهرة',
        'السبعين',
        'الحرازات',
        'بريمان',
        'أم السلم',
        'الحرس الوطني',
        'الهدى',
        'الملائكة',
        'الشرفية',
        'القريات',
        'المشاعلة',
        'المثلث',
        'الثغر',
      ]),
    ],
  ),
  CityData(
    name: 'مكة',
    directions: [
      CityDirection(name: 'مكة', neighborhoods: [
        'العزيزية',
        'الزاهر',
        'المعابدة',
        'الرصيفة',
        'العوالي',
        'الشوقية',
        'النزهة',
        'التيسير',
        'الشرائع',
        'الخالدية',
        'أجياد',
        'المسفلة',
        'الجميزة',
        'الهنداوية',
        'الطارقية',
      ]),
    ],
  ),
  CityData(
    name: 'المدينة',
    directions: [
      CityDirection(name: 'المدينة', neighborhoods: [
        'العوالي',
        'قباء',
        'السلام',
        'الرانوناء',
        'أحد',
        'بدر',
        'الحرة الشرقية',
        'الحرة الغربية',
        'ذياب',
        'شوران',
        'المسجد النبوي',
        'العنبرية',
        'الجماوات',
        'أبيار علي',
        'الدويمة',
      ]),
    ],
  ),
  CityData(
    name: 'الدمام',
    directions: [
      CityDirection(name: 'الدمام', neighborhoods: [
        'السلام',
        'الفردوس',
        'الطبيشي',
        'الشاطئ',
        'الحمام',
        'البديع',
        'الريان',
        'المزروعية',
        'الجامعيين',
        'الهدا',
        'الشعلة',
        'النخيل',
        'الإسكان',
        'المنار',
        'الجنوبية',
      ]),
    ],
  ),
  CityData(
    name: 'الخبر',
    directions: [
      CityDirection(name: 'الخبر', neighborhoods: [
        'العليا',
        'الراكة',
        'الخور',
        'الجامعة',
        'الشبيلي',
        'الغرامي',
        'اليرموك',
        'الحزام',
        'الفيحاء',
        'الكورنيش',
        'البحر',
        'العرين',
        'الضيافة',
        'العسيري',
        'المتحف',
      ]),
    ],
  ),
  CityData(
    name: 'الظهران',
    directions: [
      CityDirection(name: 'الظهران', neighborhoods: [
        'الدوحة',
        'الراكة',
        'الحزام الأخضر',
        'الشراع',
        'الجامعات',
        'الجفالة',
        'القشلة',
        'السلطان',
        'الندى',
        'البساتين',
      ]),
    ],
  ),
  CityData(
    name: 'الطائف',
    directions: [
      CityDirection(name: 'الطائف', neighborhoods: [
        'السلامة',
        'شبرا',
        'الفيصلية',
        'الروضة',
        'القيم',
        'السداد',
        'أم العراد',
        'النسيم',
        'الحوية',
        'جبرة',
        'اللحيان',
        'قيا',
        'الهدا',
        'الشفا',
        'رحاب',
      ]),
    ],
  ),
  CityData(
    name: 'تبوك',
    directions: [
      CityDirection(name: 'تبوك', neighborhoods: [
        'المهرجانات',
        'السلام',
        'المروج',
        'الريان',
        'السعادة',
        'الملك فهد',
        'الصناعية',
        'الرميثاء',
        'البديعة',
        'الحوية',
        'بجلي',
        'قرى',
        'الإسكان',
        'البوادي',
        'المدينة',
      ]),
    ],
  ),
  CityData(
    name: 'أبها',
    directions: [
      CityDirection(name: 'أبها', neighborhoods: [
        'المروج',
        'النسيم',
        'الشفاء',
        'المنتزه',
        'الحسينية',
        'الربوة',
        'أحد رفيدة',
        'المحالة',
        'العرين',
        'السد',
        'المغرد',
        'العرض',
        'الضباب',
        'اليمانية',
        'بني مالك',
      ]),
    ],
  ),
  CityData(
    name: 'حائل',
    directions: [
      CityDirection(name: 'حائل', neighborhoods: [
        'الريان',
        'الملك خالد',
        'الصناعية',
        'الوادي',
        'الزيتون',
        'المطار',
        'الضحية',
        'العالية',
        'جبل السمراء',
        'قفار',
        'الشنان',
        'توارن',
        'السميراء',
        'بقعاء',
        'العش',
      ]),
    ],
  ),
  CityData(
    name: 'بريدة',
    directions: [
      CityDirection(name: 'بريدة', neighborhoods: [
        'النخيل',
        'الفيصلية',
        'الصفراء',
        'الملك فهد',
        'السلام',
        'الربوة',
        'الروضة',
        'الخليج',
        'الصحافة',
        'الإسكان',
        'المطار',
        'النظيم',
        'الحزم',
        'العارض',
        'الدريهمية',
      ]),
    ],
  ),
  CityData(
    name: 'الأحساء',
    directions: [
      CityDirection(name: 'الأحساء', neighborhoods: [
        'المبرز',
        'الهفوف',
        'العمران',
        'الجفر',
        'الخالدية',
        'الفاضلية',
        'الريان',
        'المزاوي',
        'المنصورة',
        'الحزم',
        'البرود',
        'شعبة',
        'التويثير',
        'الخبراء',
        'بني معن',
      ]),
    ],
  ),
  CityData(
    name: 'نجران',
    directions: [
      CityDirection(name: 'نجران', neighborhoods: [
        'الجنينة',
        'المشاعر',
        'الصايش',
        'الشفاء',
        'الملك عبدالعزيز',
        'الملك فهد',
        'الإسكان',
        'السلم',
        'الحزام الأخضر',
        'البديع',
        'خالدية',
        'مباغ',
        'الأمير مشعل',
        'الأخدود',
        'العريسة',
      ]),
    ],
  ),
  CityData(
    name: 'جازان',
    directions: [
      CityDirection(name: 'جازان', neighborhoods: [
        'المدينة',
        'الأحد',
        'الريان',
        'الخالدية',
        'السلطان',
        'المحاميد',
        'أبو عريش',
        'صامطة',
        'صبيا',
        'ضمد',
        'الدرب',
        'بيش',
        'الطوال',
        'أحد المسارحة',
        'العيدابي',
      ]),
    ],
  ),
  CityData(
    name: 'ينبع',
    directions: [
      CityDirection(name: 'ينبع', neighborhoods: [
        'ينبع النخل',
        'ينبع البحر',
        'الصبح',
        'السلام',
        'الرمال',
        'المدينة الصناعية',
        'الحوراء',
        'الشاطئ',
        'البادية',
        'الجابرية',
        'العطاف',
        'النخيل',
        'المحطة',
        'الفردوس',
        'الروضة',
      ]),
    ],
  ),
];

CityData? cityByName(String name) {
  for (final c in kCities) {
    if (c.name == name) return c;
  }
  return null;
}

/// كل أسماء المدن مرتبة (للقوائم والفلاتر).
List<String> get kCityNames => [for (final c in kCities) c.name];

/// إحداثيات تقريبية لمراكز المدن — تُستخدم لربط موقع المستخدم المباشر
/// بأقرب مدينة (تحديد تقريبي بدون خدمة عكس إحداثيات).
const Map<String, List<double>> _cityCenters = {
  'الرياض': [24.7136, 46.6753],
  'جدة': [21.4858, 39.1925],
  'مكة': [21.3891, 39.8579],
  'المدينة': [24.4672, 39.6111],
  'الدمام': [26.4207, 50.0888],
  'الخبر': [26.2172, 50.1971],
  'الظهران': [26.2667, 50.15],
  'الطائف': [21.2703, 40.4158],
  'تبوك': [28.3838, 36.5550],
  'أبها': [18.2164, 42.5053],
  'حائل': [27.5114, 41.7201],
  'بريدة': [26.3260, 43.9750],
  'الأحساء': [25.3833, 49.5833],
  'نجران': [17.4924, 44.1277],
  'جازان': [16.8894, 42.5511],
  'ينبع': [24.0889, 38.0624],
};

/// أقرب مدينة إلى إحداثيات معينة (تحديد تقريبي بمسافة هافرساين).
String nearestCity(double lat, double lng) {
  String best = kCityNames.isNotEmpty ? kCityNames.first : '';
  var bestDistance = double.infinity;
  for (final city in kCities) {
    final center = _cityCenters[city.name];
    if (center == null || center.length < 2) continue;
    final d = _haversine(lat, lng, center[0], center[1]);
    if (d < bestDistance) {
      bestDistance = d;
      best = city.name;
    }
  }
  return best;
}

double _haversine(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _radians(lat2 - lat1);
  final dLng = _radians(lng2 - lng1);
  final a = _sin2(dLat / 2) +
      _cos(_radians(lat1)) * _cos(_radians(lat2)) * _sin2(dLng / 2);
  return 2 * r * _asin(_sqrt(a));
}

double _radians(double deg) => deg * 3.141592653589793 / 180;

double _sin2(double x) {
  final s = _sin(x);
  return s * s;
}

double _sin(double x) {
  var term = x;
  var sum = x;
  for (var i = 1; i < 8; i++) {
    term = -term * x * x / ((2 * i) * (2 * i + 1));
    sum += term;
  }
  return sum;
}

double _cos(double x) {
  var term = 1.0;
  var sum = 1.0;
  for (var i = 1; i < 8; i++) {
    term = -term * x * x / ((2 * i - 1) * (2 * i));
    sum += term;
  }
  return sum;
}

double _asin(double x) {
  var t = x;
  var sum = x;
  var n = 1;
  while (n < 12) {
    t = t * (1 - 1.0 / (2 * n)) * (1 - 1.0 / (2 * n)) * x * x * 4;
    sum += t / (2 * n + 1);
    n++;
  }
  return sum;
}

double _sqrt(double x) {
  if (x <= 0) return 0;
  var guess = x / 2;
  for (var i = 0; i < 20; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}
