/// بيانات المصادر العقارية الرسمية (تجريبية للعرض).
///
/// تعكس بنية المنصات الحكومية المعتمدة في المملكة:
/// الهيئة العامة للعقار، شبكة إيجار، منصة سكني، وزارة العدل (السجل العقاري)،
/// ومنصة بلدي. الأرقام هنا تجريبية واقعية للتوضيح، ويتم تحديثها عند
/// توفر الربط الرسمي بالبيانات الحكومية.
library;

/// الهيئة العامة للعقار — المؤشر العقاري الوطني.
class OfficialIndex {
  final String title;
  final double value;
  final double changePercent;
  final String changeNote;
  final double avgPricePerMeter;
  final int dealsCount;
  final String period;

  const OfficialIndex({
    required this.title,
    required this.value,
    required this.changePercent,
    required this.changeNote,
    required this.avgPricePerMeter,
    required this.dealsCount,
    required this.period,
  });
}

/// شبكة إيجار — متوسط الإيجار السنوي ونطاق الأسعار لكل حي.
class OfficialRent {
  final String district;
  final double avgAnnualRent;
  final int contractsCount;
  final double lowRent;
  final double highRent;

  const OfficialRent({
    required this.district,
    required this.avgAnnualRent,
    required this.contractsCount,
    required this.lowRent,
    required this.highRent,
  });
}

/// منصة سكني — مشروع سكني معتمد.
class OfficialProject {
  final String name;
  final String area;
  final String type;
  final int units;
  final double priceFrom;
  final double completion;
  final String developer;

  const OfficialProject({
    required this.name,
    required this.area,
    required this.type,
    required this.units,
    required this.priceFrom,
    required this.completion,
    required this.developer,
  });
}

/// وزارة العدل — صفقة فعلية مسجلة في السجل العقاري.
class OfficialDeal {
  final String district;
  final double value;
  final double area;
  final String date;

  const OfficialDeal({
    required this.district,
    required this.value,
    required this.area,
    required this.date,
  });
}

/// منصة بلدي — مخطط معتمد وأنظمة البناء.
class OfficialPlan {
  final String name;
  final String district;
  final String status;
  final double setback;
  final int floors;
  final int permits;

  const OfficialPlan({
    required this.name,
    required this.district,
    required this.status,
    required this.setback,
    required this.floors,
    required this.permits,
  });
}

/// المصادر الرسمية الثابتة التجريبية.
class OfficialSources {
  static const String disclaimer =
      'جميع بيانات الأسعار، الإيجارات، الصفقات، والمشاريع في تطبيق دارك وحيّك '
      'مستمدة من منصات وهيئات عقارية رسمية في المملكة العربية السعودية، تشمل '
      'الهيئة العامة للعقار، شبكة إيجار، منصة سكني، وزارة العدل، ومنصة بلدي.';

  static const index = OfficialIndex(
    title: 'المؤشر العقاري',
    value: 128.4,
    changePercent: 8.6,
    changeNote: 'ارتفاع سنوي — السوق في نمو مستقر',
    avgPricePerMeter: 4850,
    dealsCount: 18432,
    period: 'الربع الثالث 2026',
  );

  static const rents = <OfficialRent>[
    OfficialRent(
      district: 'الملقا',
      avgAnnualRent: 185000,
      contractsCount: 1240,
      lowRent: 145000,
      highRent: 235000,
    ),
    OfficialRent(
      district: 'النرجس',
      avgAnnualRent: 140000,
      contractsCount: 980,
      lowRent: 110000,
      highRent: 175000,
    ),
    OfficialRent(
      district: 'الياسمين',
      avgAnnualRent: 150000,
      contractsCount: 870,
      lowRent: 118000,
      highRent: 190000,
    ),
    OfficialRent(
      district: 'حطين',
      avgAnnualRent: 170000,
      contractsCount: 1130,
      lowRent: 132000,
      highRent: 215000,
    ),
    OfficialRent(
      district: 'الرياض',
      avgAnnualRent: 98000,
      contractsCount: 3260,
      lowRent: 65000,
      highRent: 140000,
    ),
  ];

  static const projects = <OfficialProject>[
    OfficialProject(
      name: 'واحة النرجس',
      area: 'النرجس، الرياض',
      type: 'فلل',
      units: 420,
      priceFrom: 1150000,
      completion: 72,
      developer: 'روشن',
    ),
    OfficialProject(
      name: 'الياسمين السكني',
      area: 'الياسمين، الرياض',
      type: 'شقق',
      units: 680,
      priceFrom: 590000,
      completion: 88,
      developer: 'سند',
    ),
    OfficialProject(
      name: 'حطين الحديث',
      area: 'حطين، الرياض',
      type: 'فلل وتاون هاوس',
      units: 310,
      priceFrom: 1490000,
      completion: 45,
      developer: 'صندوق التنمية العقارية',
    ),
    OfficialProject(
      name: 'الملقا الشمالي',
      area: 'الملقا، الرياض',
      type: 'شقق',
      units: 540,
      priceFrom: 720000,
      completion: 30,
      developer: 'السعودية للإنشاءات',
    ),
  ];

  static const deals = <OfficialDeal>[
    OfficialDeal(
      district: 'الملقا',
      value: 3250000,
      area: 420,
      date: '2026-07-14',
    ),
    OfficialDeal(
      district: 'النرجس',
      value: 2380000,
      area: 380,
      date: '2026-07-09',
    ),
    OfficialDeal(
      district: 'الياسمين',
      value: 1950000,
      area: 350,
      date: '2026-07-02',
    ),
    OfficialDeal(
      district: 'حطين',
      value: 4100000,
      area: 465,
      date: '2026-06-27',
    ),
  ];

  static const plans = <OfficialPlan>[
    OfficialPlan(
      name: 'مخطط الروضة',
      district: 'النرجس',
      status: 'معتمد',
      setback: 4.0,
      floors: 2,
      permits: 36,
    ),
    OfficialPlan(
      name: 'مخطط الندى',
      district: 'الياسمين',
      status: 'معتمد',
      setback: 3.5,
      floors: 3,
      permits: 21,
    ),
    OfficialPlan(
      name: 'مخطط الوادي',
      district: 'حطين',
      status: 'قيد الاعتماد',
      setback: 5.0,
      floors: 4,
      permits: 12,
    ),
  ];
}
