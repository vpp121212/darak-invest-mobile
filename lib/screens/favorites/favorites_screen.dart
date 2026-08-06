import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/property_card.dart';

@RoutePage()
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favoritesProvider);
    final catalogue = ref.watch(propertiesProvider);
    final properties = catalogue.properties
        .where((p) => favourites.contains(p.id))
        .toList();

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        centerTitle: true,
        title: Text(
          'المفضلة (${properties.length})',
          style: GoogleFonts.cairo(color: primary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: properties.isEmpty
          ? _empty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final p = properties[index];
                return PropertyCard(
                  property: p,
                  onTap: () => context.pushRoute(PropertyDetailRoute(property: p)),
                  onFavorite: () => ref.read(favoritesProvider.notifier).toggle(p.id),
                  isFavorite: true,
                );
              },
            ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 60, color: textMuted),
          const SizedBox(height: 12),
          Text(
            'لا توجد عقارات مفضلة بعد',
            style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'اضغط على أيقونة القلب في العقار لحفظه هنا',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
