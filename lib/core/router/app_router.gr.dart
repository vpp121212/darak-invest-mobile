// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

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
