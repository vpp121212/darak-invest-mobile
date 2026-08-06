// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AgentsScreen]
class AgentsRoute extends PageRouteInfo<void> {
  const AgentsRoute({List<PageRouteInfo>? children})
      : super(AgentsRoute.name, initialChildren: children);

  static const String name = 'AgentsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AgentsScreen();
    },
  );
}

/// generated route for
/// [AppShell]
class AppShellRoute extends PageRouteInfo<void> {
  const AppShellRoute({List<PageRouteInfo>? children})
      : super(AppShellRoute.name, initialChildren: children);

  static const String name = 'AppShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AppShell();
    },
  );
}

/// generated route for
/// [CompareScreen]
class CompareRoute extends PageRouteInfo<void> {
  const CompareRoute({List<PageRouteInfo>? children})
      : super(CompareRoute.name, initialChildren: children);

  static const String name = 'CompareRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CompareScreen();
    },
  );
}

/// generated route for
/// [EstimateScreen]
class EstimateRoute extends PageRouteInfo<EstimateRouteArgs> {
  EstimateRoute({Key? key, Property? property, List<PageRouteInfo>? children})
      : super(
          EstimateRoute.name,
          args: EstimateRouteArgs(key: key, property: property),
          initialChildren: children,
        );

  static const String name = 'EstimateRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EstimateRouteArgs>(
        orElse: () => const EstimateRouteArgs(),
      );
      return EstimateScreen(key: args.key, property: args.property);
    },
  );
}

class EstimateRouteArgs {
  const EstimateRouteArgs({this.key, this.property});

  final Key? key;

  final Property? property;

  @override
  String toString() {
    return 'EstimateRouteArgs{key: $key, property: $property}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EstimateRouteArgs) return false;
    return key == other.key && property == other.property;
  }

  @override
  int get hashCode => key.hashCode ^ property.hashCode;
}

/// generated route for
/// [FavoritesScreen]
class FavoritesRoute extends PageRouteInfo<void> {
  const FavoritesRoute({List<PageRouteInfo>? children})
      : super(FavoritesRoute.name, initialChildren: children);

  static const String name = 'FavoritesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FavoritesScreen();
    },
  );
}

/// generated route for
/// [FinanceScreen]
class FinanceRoute extends PageRouteInfo<FinanceRouteArgs> {
  FinanceRoute({Key? key, double? initialPrice, List<PageRouteInfo>? children})
      : super(
          FinanceRoute.name,
          args: FinanceRouteArgs(key: key, initialPrice: initialPrice),
          initialChildren: children,
        );

  static const String name = 'FinanceRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FinanceRouteArgs>(
        orElse: () => const FinanceRouteArgs(),
      );
      return FinanceScreen(key: args.key, initialPrice: args.initialPrice);
    },
  );
}

class FinanceRouteArgs {
  const FinanceRouteArgs({this.key, this.initialPrice});

  final Key? key;

  final double? initialPrice;

  @override
  String toString() {
    return 'FinanceRouteArgs{key: $key, initialPrice: $initialPrice}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FinanceRouteArgs) return false;
    return key == other.key && initialPrice == other.initialPrice;
  }

  @override
  int get hashCode => key.hashCode ^ initialPrice.hashCode;
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginScreen();
    },
  );
}

/// generated route for
/// [MapScreen]
class MapRoute extends PageRouteInfo<MapRouteArgs> {
  MapRoute({Key? key, Property? initialProperty, List<PageRouteInfo>? children})
      : super(
          MapRoute.name,
          args: MapRouteArgs(key: key, initialProperty: initialProperty),
          initialChildren: children,
        );

  static const String name = 'MapRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MapRouteArgs>(
        orElse: () => const MapRouteArgs(),
      );
      return MapScreen(key: args.key, initialProperty: args.initialProperty);
    },
  );
}

class MapRouteArgs {
  const MapRouteArgs({this.key, this.initialProperty});

  final Key? key;

  final Property? initialProperty;

  @override
  String toString() {
    return 'MapRouteArgs{key: $key, initialProperty: $initialProperty}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapRouteArgs) return false;
    return key == other.key && initialProperty == other.initialProperty;
  }

  @override
  int get hashCode => key.hashCode ^ initialProperty.hashCode;
}

/// generated route for
/// [MarketReportScreen]
class MarketReportRoute extends PageRouteInfo<void> {
  const MarketReportRoute({List<PageRouteInfo>? children})
      : super(MarketReportRoute.name, initialChildren: children);

  static const String name = 'MarketReportRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MarketReportScreen();
    },
  );
}

/// generated route for
/// [NeighborhoodDetailScreen]
class NeighborhoodDetailRoute
    extends PageRouteInfo<NeighborhoodDetailRouteArgs> {
  NeighborhoodDetailRoute({
    Key? key,
    required String district,
    List<PageRouteInfo>? children,
  }) : super(
          NeighborhoodDetailRoute.name,
          args: NeighborhoodDetailRouteArgs(key: key, district: district),
          initialChildren: children,
        );

  static const String name = 'NeighborhoodDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NeighborhoodDetailRouteArgs>();
      return NeighborhoodDetailScreen(key: args.key, district: args.district);
    },
  );
}

class NeighborhoodDetailRouteArgs {
  const NeighborhoodDetailRouteArgs({this.key, required this.district});

  final Key? key;

  final String district;

  @override
  String toString() {
    return 'NeighborhoodDetailRouteArgs{key: $key, district: $district}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NeighborhoodDetailRouteArgs) return false;
    return key == other.key && district == other.district;
  }

  @override
  int get hashCode => key.hashCode ^ district.hashCode;
}

/// generated route for
/// [PropertyDetailScreen]
class PropertyDetailRoute extends PageRouteInfo<PropertyDetailRouteArgs> {
  PropertyDetailRoute({
    Key? key,
    required Property property,
    List<PageRouteInfo>? children,
  }) : super(
          PropertyDetailRoute.name,
          args: PropertyDetailRouteArgs(key: key, property: property),
          initialChildren: children,
        );

  static const String name = 'PropertyDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PropertyDetailRouteArgs>();
      return PropertyDetailScreen(key: args.key, property: args.property);
    },
  );
}

class PropertyDetailRouteArgs {
  const PropertyDetailRouteArgs({this.key, required this.property});

  final Key? key;

  final Property property;

  @override
  String toString() {
    return 'PropertyDetailRouteArgs{key: $key, property: $property}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PropertyDetailRouteArgs) return false;
    return key == other.key && property == other.property;
  }

  @override
  int get hashCode => key.hashCode ^ property.hashCode;
}

/// generated route for
/// [PulseScreen]
class PulseRoute extends PageRouteInfo<PulseRouteArgs> {
  PulseRoute({Key? key, String? district, List<PageRouteInfo>? children})
      : super(
          PulseRoute.name,
          args: PulseRouteArgs(key: key, district: district),
          initialChildren: children,
        );

  static const String name = 'PulseRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PulseRouteArgs>(
        orElse: () => const PulseRouteArgs(),
      );
      return PulseScreen(key: args.key, district: args.district);
    },
  );
}

class PulseRouteArgs {
  const PulseRouteArgs({this.key, this.district});

  final Key? key;

  final String? district;

  @override
  String toString() {
    return 'PulseRouteArgs{key: $key, district: $district}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PulseRouteArgs) return false;
    return key == other.key && district == other.district;
  }

  @override
  int get hashCode => key.hashCode ^ district.hashCode;
}

/// generated route for
/// [RegisterScreen]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
      : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RegisterScreen();
    },
  );
}

/// generated route for
/// [RoiScreen]
class RoiRoute extends PageRouteInfo<RoiRouteArgs> {
  RoiRoute({Key? key, Property? property, List<PageRouteInfo>? children})
      : super(
          RoiRoute.name,
          args: RoiRouteArgs(key: key, property: property),
          initialChildren: children,
        );

  static const String name = 'RoiRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RoiRouteArgs>(
        orElse: () => const RoiRouteArgs(),
      );
      return RoiScreen(key: args.key, property: args.property);
    },
  );
}

class RoiRouteArgs {
  const RoiRouteArgs({this.key, this.property});

  final Key? key;

  final Property? property;

  @override
  String toString() {
    return 'RoiRouteArgs{key: $key, property: $property}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RoiRouteArgs) return false;
    return key == other.key && property == other.property;
  }

  @override
  int get hashCode => key.hashCode ^ property.hashCode;
}

/// generated route for
/// [SearchScreen]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
      : super(SearchRoute.name, initialChildren: children);

  static const String name = 'SearchRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SearchScreen();
    },
  );
}
