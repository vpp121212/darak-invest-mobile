/// A curated neighborhood investment opportunity shown in the pulse radar.
class InvestmentOpportunity {
  final String tag;
  final String district;
  final String title;
  final String subtitle;
  final double annualGrowth;
  final double fundingPercent;
  final double fundingAmount;
  final double minInvestment;

  const InvestmentOpportunity({
    required this.tag,
    required this.district,
    required this.title,
    required this.subtitle,
    required this.annualGrowth,
    required this.fundingPercent,
    required this.fundingAmount,
    required this.minInvestment,
  });
}

/// Static seed data until the backend exposes a radar endpoint.
const List<InvestmentOpportunity> kInvestmentOpportunities = [
  InvestmentOpportunity(
    tag: 'الأكثر نمواً في الرياض',
    district: 'حي الملقا',
    title: 'مربع الاستثمار',
    subtitle: 'عقارات تجارية وسكنية فاخرة',
    annualGrowth: 15.8,
    fundingPercent: 75,
    fundingAmount: 3750000,
    minInvestment: 1000,
  ),
];
