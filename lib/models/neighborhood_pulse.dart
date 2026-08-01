class NeighborhoodPulse {
  final String city;
  final String district;
  final num? avgRent;
  final num? avgSale;
  final num? roi;
  final List<String> metroStations;
  final List<String> nearbyProjects;
  final bool sportsBoulevard;
  final num? walkScore;
  final List<String> greenSpaces;
  final num? futureValueGrowth;
  final String? dataSource;

  const NeighborhoodPulse({
    required this.city,
    required this.district,
    this.avgRent,
    this.avgSale,
    this.roi,
    this.metroStations = const [],
    this.nearbyProjects = const [],
    this.sportsBoulevard = false,
    this.walkScore,
    this.greenSpaces = const [],
    this.futureValueGrowth,
    this.dataSource,
  });

  factory NeighborhoodPulse.fromJson(Map<String, dynamic> json) {
    return NeighborhoodPulse(
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      avgRent: json['avg_rent'],
      avgSale: json['avg_sale'],
      roi: json['roi'],
      metroStations: _asList(json['metro_stations']),
      nearbyProjects: _asList(json['nearby_projects']),
      sportsBoulevard: json['sports_boulevard'] == true,
      walkScore: json['walk_score'],
      greenSpaces: _asList(json['green_spaces']),
      futureValueGrowth: json['future_value_growth'],
      dataSource: json['data_source'],
    );
  }

  static List<String> _asList(dynamic v) {
    if (v == null) return const [];
    return (v as List).map((e) => e.toString()).toList();
  }
}
