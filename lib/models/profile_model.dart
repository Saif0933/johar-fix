class OrderStats {
  final int totalCount;
  final int pending;
  final int completed;
  final int cancelled;
  final double totalSpend;

  OrderStats({
    required this.totalCount,
    required this.pending,
    required this.completed,
    required this.cancelled,
    required this.totalSpend,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      totalCount: json['total_count'] as int? ?? json['totalCount'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      cancelled: json['cancelled'] as int? ?? 0,
      totalSpend: double.tryParse(json['total_spend']?.toString() ?? json['totalSpend']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_count': totalCount,
      'pending': pending,
      'completed': completed,
      'cancelled': cancelled,
      'total_spend': totalSpend,
    };
  }
}

class ProfileModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final OrderStats? orderStats;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.orderStats,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone']?.toString(),
      address: json['address'] as String?,
      orderStats: json['orderStats'] != null 
          ? OrderStats.fromJson(json['orderStats'] as Map<String, dynamic>)
          : json['order_stats'] != null
              ? OrderStats.fromJson(json['order_stats'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'order_stats': orderStats?.toJson(),
    };
  }

  ProfileModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    OrderStats? orderStats,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      orderStats: orderStats ?? this.orderStats,
    );
  }
}
