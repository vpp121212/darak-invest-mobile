/// Curated neighborhood data used by the home neighborhoods rail and the
/// neighborhood detail screen (works offline, mirroring the pulse data).
class NeighborhoodInfo {
  final String name;
  final String city;
  final double avgPrice;
  final double avgRent;
  final double roi;
  final double growth;
  final String tagline;

  const NeighborhoodInfo({
    required this.name,
    required this.city,
    required this.avgPrice,
    required this.avgRent,
    required this.roi,
    required this.growth,
    required this.tagline,
  });
}

const List<NeighborhoodInfo> kNeighborhoods = [
  NeighborhoodInfo(
    name: 'الملقا',
    city: 'الرياض',
    avgPrice: 3150000,
    avgRent: 185000,
    roi: 5.9,
    growth: 15.8,
    tagline: 'مربع الاستثمار — عقارات تجارية وسكنية فاخرة',
  ),
  NeighborhoodInfo(
    name: 'النرجس',
    city: 'الرياض',
    avgPrice: 2250000,
    avgRent: 140000,
    roi: 6.2,
    growth: 12.4,
    tagline: 'حي العائلات — هادئ وقريب من الخدمات',
  ),
  NeighborhoodInfo(
    name: 'الياسمين',
    city: 'الرياض',
    avgPrice: 2450000,
    avgRent: 150000,
    roi: 6.1,
    growth: 11.2,
    tagline: 'فلل حديثة ومساحات خضراء واسعة',
  ),
  NeighborhoodInfo(
    name: 'حطين',
    city: 'الرياض',
    avgPrice: 2850000,
    avgRent: 170000,
    roi: 6.0,
    growth: 10.5,
    tagline: 'مجاور للرياض بوليفارد وأبرز الوجهات',
  ),
  NeighborhoodInfo(
    name: 'المربع',
    city: 'الرياض',
    avgPrice: 4200000,
    avgRent: 230000,
    roi: 5.5,
    growth: 9.8,
    tagline: 'حي الأعمال — ناطحات سحاب ومكاتب',
  ),
  NeighborhoodInfo(
    name: 'العليا',
    city: 'الرياض',
    avgPrice: 3800000,
    avgRent: 210000,
    roi: 5.5,
    growth: 8.6,
    tagline: 'قلب الرياض التجاري وسط المدينة',
  ),
  NeighborhoodInfo(
    name: 'الصحافة',
    city: 'الرياض',
    avgPrice: 1950000,
    avgRent: 120000,
    roi: 6.2,
    growth: 7.9,
    tagline: 'خيار اقتصادي ممتاز للمستثمرين',
  ),
  NeighborhoodInfo(
    name: 'الورود',
    city: 'الرياض',
    avgPrice: 2750000,
    avgRent: 160000,
    roi: 5.8,
    growth: 8.1,
    tagline: 'فيلات راقية بموقع مميز في شمال الرياض',
  ),
];
