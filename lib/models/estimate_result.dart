class EstimateResult {
  final num? expected;
  final num? suitable;
  final num? maximum;
  final num? saleChance;
  final int? sampleSize;
  final String? message;

  const EstimateResult({
    this.expected,
    this.suitable,
    this.maximum,
    this.saleChance,
    this.sampleSize,
    this.message,
  });

  bool get isEmpty =>
      expected == null && suitable == null && maximum == null && saleChance == null;

  factory EstimateResult.fromJson(Map<String, dynamic> json) {
    return EstimateResult(
      expected: json['expected'],
      suitable: json['suitable'],
      maximum: json['maximum'],
      saleChance: json['saleChance'],
      sampleSize: json['sampleSize'],
      message: json['message'],
    );
  }
}
