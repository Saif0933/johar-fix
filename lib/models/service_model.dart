class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final double? originalPrice;
  final String? image;
  final String? rating;
  final int? reviewsCount;
  int qty; // Helper for cart quantities

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    this.originalPrice,
    this.image,
    this.rating,
    this.reviewsCount,
    this.qty = 0,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // base_price might come as string or double
    final rawBasePrice = json['base_price'] ?? json['price'];
    final basePrice = double.tryParse(rawBasePrice?.toString() ?? '0') ?? 0.0;
    
    final rawOriginalPrice = json['original_price'] ?? json['originalPrice'];
    final originalPrice = rawOriginalPrice != null 
        ? (double.tryParse(rawOriginalPrice.toString()) ?? 0.0) 
        : null;

    final idVal = json['id']?.toString() ?? '';

    return ServiceModel(
      id: idVal,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      basePrice: basePrice,
      originalPrice: originalPrice,
      image: json['image'] as String?,
      rating: json['rating']?.toString() ?? '4.8',
      reviewsCount: json['reviews_count'] as int? ?? json['reviews'] as int? ?? 120,
      qty: json['qty'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'base_price': basePrice,
      'original_price': originalPrice,
      'image': image,
      'rating': rating,
      'reviews_count': reviewsCount,
      'qty': qty,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    double? basePrice,
    double? originalPrice,
    String? image,
    String? rating,
    int? reviewsCount,
    int? qty,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      originalPrice: originalPrice ?? this.originalPrice,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      qty: qty ?? this.qty,
    );
  }
}
