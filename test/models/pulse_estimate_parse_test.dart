import 'package:darak_wa_hayk/models/estimate_result.dart';
import 'package:darak_wa_hayk/models/neighborhood_pulse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse real pulse JSON', () {
    const response = {
      'success': true,
      'pulse': {
        'id': 49265,
        'city': 'الرياض',
        'district': 'الملقا',
        'avg_rent': 60000,
        'avg_sale': 1800000,
        'roi': 7.5,
        'metro_stations': [
          {'name': 'المروج', 'line': 'الأزرق', 'year': 2024, 'distance': '8 دقائق'},
        ],
        'nearby_projects': [
          {'name': 'المربع الجديد', 'type': 'مشروع ترفيهي', 'year': 2030, 'distance': '8 دقائق'},
        ],
        'sports_boulevard': true,
        'walk_score': 78,
        'green_spaces': [
          {'name': 'حديقة الملقا', 'distance': '5 دقائق'},
        ],
        'future_value_growth': 18,
        'data_source': 'تحليل السوق 2024-2026',
      },
    };
    final pulse = NeighborhoodPulse.fromJson(response['pulse'] as Map<String, dynamic>);
    expect(pulse.district, 'الملقا');
    expect(pulse.metroStations, ['المروج (8 دقائق)']);
    expect(pulse.greenSpaces, ['حديقة الملقا (5 دقائق)']);
    expect(pulse.avgRent, 60000);
  });

  test('parse real estimate JSON', () {
    const response = {
      'success': true,
      'estimation': {
        'expected': 3150000,
        'suitable': 3241667,
        'maximum': 3850000,
        'saleChance': 50,
        'sampleSize': 2,
      },
    };
    final result =
        EstimateResult.fromJson(response['estimation'] as Map<String, dynamic>);
    expect(result.expected, 3150000);
    expect(result.saleChance, 50);
    expect(result.isEmpty, false);
  });

  test('parse estimate no-data JSON', () {
    const response = {
      'success': true,
      'estimation': {
        'expected': null,
        'suitable': null,
        'maximum': null,
        'saleChance': null,
        'message': 'لا توجد بيانات كافية',
        'sampleSize': 0,
      },
    };
    final result =
        EstimateResult.fromJson(response['estimation'] as Map<String, dynamic>);
    expect(result.isEmpty, true);
    expect(result.sampleSize, 0);
  });
}
