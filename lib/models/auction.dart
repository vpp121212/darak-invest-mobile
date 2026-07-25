class Auction {
  final String id;
  final String title;
  final String location;
  final double price;
  final double currentBid;
  final String imageUrl;
  final DateTime endTime;
  final int bidsCount;
  final String description;

  Auction({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.currentBid,
    required this.imageUrl,
    required this.endTime,
    required this.bidsCount,
    required this.description,
  });

  Duration get timeRemaining {
    final now = DateTime.now();
    if (endTime.isAfter(now)) {
      return endTime.difference(now);
    }
    return Duration.zero;
  }

  bool get isActive => timeRemaining > Duration.zero;

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currentBid: (json['currentBid'] ?? json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime']) ?? DateTime.now()
          : DateTime.now(),
      bidsCount: json['bidsCount'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'location': location,
      'price': price,
      'currentBid': currentBid,
      'imageUrl': imageUrl,
      'endTime': endTime.toIso8601String(),
      'bidsCount': bidsCount,
      'description': description,
    };
  }
}
