class AgentInfo {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatar;

  AgentInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatar,
  });

  factory AgentInfo.fromJson(Map<String, dynamic> json) {
    return AgentInfo(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (avatar != null) 'avatar': avatar,
    };
  }
}

class Property {
  final String id;
  final String title;
  final String type;
  final String loc;
  final String district;
  final String city;
  final double price;
  final int rooms;
  final int baths;
  final int cars;
  final double area;
  final int year;
  final int age;
  final String status;
  final double lat;
  final double lng;
  final String street;
  final int streetW;
  final String facing;
  final String purpose;
  final String desc;
  final List<String> images;
  final List<String> features;
  final String panoramicImage;
  final List<String> panoramicImages;
  final String model3dUrl;
  final List<String> model3dUrls;
  final int trust;
  final AgentInfo? agent;

  Property({
    required this.id,
    required this.title,
    required this.type,
    required this.loc,
    required this.district,
    required this.city,
    required this.price,
    required this.rooms,
    required this.baths,
    required this.cars,
    required this.area,
    required this.year,
    required this.age,
    required this.status,
    required this.lat,
    required this.lng,
    required this.street,
    required this.streetW,
    required this.facing,
    required this.purpose,
    required this.desc,
    required this.images,
    required this.features,
    this.panoramicImage = '',
    this.panoramicImages = const [],
    this.model3dUrl = '',
    this.model3dUrls = const [],
    required this.trust,
    this.agent,
  });

  String get formattedPrice {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)} مليون';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)} ألف';
    }
    return price.toStringAsFixed(0);
  }

  String get mainImage => images.isNotEmpty ? images.first : '';

  Property copyWith({
    List<String>? images,
    String? panoramicImage,
    List<String>? panoramicImages,
    String? model3dUrl,
    List<String>? model3dUrls,
  }) {
    return Property(
      id: id,
      title: title,
      type: type,
      loc: loc,
      district: district,
      city: city,
      price: price,
      rooms: rooms,
      baths: baths,
      cars: cars,
      area: area,
      year: year,
      age: age,
      status: status,
      lat: lat,
      lng: lng,
      street: street,
      streetW: streetW,
      facing: facing,
      purpose: purpose,
      desc: desc,
      images: images ?? this.images,
      features: features,
      panoramicImage: panoramicImage ?? this.panoramicImage,
      panoramicImages: panoramicImages ?? this.panoramicImages,
      model3dUrl: model3dUrl ?? this.model3dUrl,
      model3dUrls: model3dUrls ?? this.model3dUrls,
      trust: trust,
      agent: agent,
    );
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      loc: json['loc'] ?? json['location'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      rooms: json['rooms'] ?? 0,
      baths: json['baths'] ?? 0,
      cars: json['cars'] ?? 0,
      area: (json['area'] ?? 0).toDouble(),
      year: json['year'] ?? 0,
      age: json['age'] ?? 0,
      status: json['status'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      street: json['street'] ?? '',
      streetW: json['streetW'] ?? 0,
      facing: json['facing'] ?? '',
      purpose: json['purpose'] ?? '',
      desc: json['desc'] ?? json['description'] ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
      panoramicImage: (json['panoramicImage'] ?? json['panoUrl'] ?? json['panorama'] ?? '').toString(),
      panoramicImages: (json['panoramicImages'] as List?)?.map((e) => e.toString()).toList() ??
          (json['scenes'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      model3dUrl: (json['model3dUrl'] ?? json['modelUrl'] ?? json['model3d'] ?? '').toString(),
      model3dUrls: (json['model3dUrls'] as List?)?.map((e) => e.toString()).toList() ??
          (json['models'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      trust: _parseTrust(json['trust']),
      agent: json['agent'] != null ? AgentInfo.fromJson(json['agent']) : null,
    );
  }

  /// The API reports trust as a status string ('verified'/'office'/'direct')
  /// while the UI renders it as a 0–100 score.
  static int _parseTrust(dynamic value) {
    if (value is num) return value.round();
    if (value is String) {
      switch (value) {
        case 'verified':
          return 100;
        case 'office':
          return 60;
        case 'direct':
          return 20;
        default:
          return int.tryParse(value) ?? 0;
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'type': type,
      'loc': loc,
      'district': district,
      'city': city,
      'price': price,
      'rooms': rooms,
      'baths': baths,
      'cars': cars,
      'area': area,
      'year': year,
      'age': age,
      'status': status,
      'lat': lat,
      'lng': lng,
      'street': street,
      'streetW': streetW,
      'facing': facing,
      'purpose': purpose,
      'desc': desc,
      'images': images,
      'features': features,
      'panoramicImage': panoramicImage,
      'panoramicImages': panoramicImages,
      'model3dUrl': model3dUrl,
      'model3dUrls': model3dUrls,
      'trust': trust,
      if (agent != null) 'agent': agent!.toJson(),
    };
  }
}
