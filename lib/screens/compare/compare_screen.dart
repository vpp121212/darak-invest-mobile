import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../models/property.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';

@RoutePage()
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(propertiesProvider);
    final properties = catalogue.properties;
    final chosen = properties.where((p) => _selected.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        centerTitle: true,
        title: Text(
          'مقارنة العقارات (${chosen.length})',
          style: GoogleFonts.cairo(color: primary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: chosen.length >= 2 ? _comparison(chosen) : _picker(properties),
    );
  }

  Widget _picker(List<Property> properties) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primarySoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tune, color: primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'اختر عقارين أو أكثر (${_selected.length}/3) للمقارنة جنباً إلى جنب',
                  style: GoogleFonts.cairo(color: textLight, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...properties.map((p) {
          final isSel = _selected.contains(p.id);
          final disabled = !isSel && _selected.length >= 3;
          return GestureDetector(
            onTap: disabled
                ? null
                : () => setState(() {
                      if (!_selected.add(p.id)) _selected.remove(p.id);
                    }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: glassFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSel ? primary : glassBorder,
                  width: isSel ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSel ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSel ? primary : textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.district} — ${Formatters.price(p.price)}',
                          style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _comparison(List<Property> chosen) {
    final rows = <(String, String? Function(Property))>[
      ('السعر', (p) => Formatters.price(p.price)),
      ('النوع', (p) => p.type),
      ('الغرض', (p) => p.purpose),
      ('الغرف', (p) => '${p.rooms}'),
      ('الحمامات', (p) => '${p.baths}'),
      ('المواقف', (p) => '${p.cars}'),
      ('المساحة', (p) => '${Formatters.number(p.area)} م²'),
      ('الواجهة', (p) => p.facing),
      ('الحي', (p) => p.district),
    ];

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: chosen.map((p) {
              return GestureDetector(
                onTap: () => setState(() => _selected.remove(p.id)),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: glassFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primary.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(color: textLight, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Icon(Icons.close, color: textMuted, size: 16),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.price(p.price),
                        style: GoogleFonts.cairo(color: primary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.rooms} غرف — ${p.area} م²',
                        style: GoogleFonts.cairo(color: textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: rows.map((row) {
                final (label, getter) = row;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: glassFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: glassBorder),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          label,
                          style: GoogleFonts.cairo(color: primary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: chosen
                              .map((p) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        getter(p) ?? '-',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(color: textLight, fontSize: 12),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
