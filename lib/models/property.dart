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
      id: json['_id'] ?? json['id'] ?? '',
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

  Property copyWith({List<String>? images}) {
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
      trust: trust,
      agent: agent,
    );
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['_id'] ?? json['id'] ?? '',
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
      trust: json['trust'] ?? 0,
      agent: json['agent'] != null ? AgentInfo.fromJson(json['agent']) : null,
    );
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
      'trust': trust,
      if (agent != null) 'agent': agent!.toJson(),
    };
  }
}
