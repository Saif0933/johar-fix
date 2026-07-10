class PaymentSummary {
  final double subtotal;
  final double serviceFee;
  final double gstRate;
  final double gstAmount;
  final double cgst;
  final double sgst;
  final double igst;
  final double discount;
  final double total;

  PaymentSummary({
    required this.subtotal,
    required this.serviceFee,
    required this.gstRate,
    required this.gstAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.discount,
    required this.total,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0.0') ?? 0.0,
      serviceFee: double.tryParse(json['service_fee']?.toString() ?? '0.0') ?? 0.0,
      gstRate: double.tryParse(json['gst_rate']?.toString() ?? '0.0') ?? 0.0,
      gstAmount: double.tryParse(json['gst_amount']?.toString() ?? '0.0') ?? 0.0,
      cgst: double.tryParse(json['cgst']?.toString() ?? '0.0') ?? 0.0,
      sgst: double.tryParse(json['sgst']?.toString() ?? '0.0') ?? 0.0,
      igst: double.tryParse(json['igst']?.toString() ?? '0.0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0.0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'service_fee': serviceFee,
      'gst_rate': gstRate,
      'gst_amount': gstAmount,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'discount': discount,
      'total': total,
    };
  }
}

class BookingModel {
  final String id;
  final String? bookingNumber;
  final String service;
  final String category;
  final String date;
  final String time;
  final String status;
  final String? rawStatus;
  final String? statusColor;
  final String price;
  final String partner;
  final String image;
  final String? partnerPhone;
  final double? partnerRating;
  final String? partnerAvatar;
  final double? partnerLatitude;
  final double? partnerLongitude;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? createdAt;
  final int? estimatedArrivalMinutes;
  final String? otpStart;
  final String? otpEnd;
  final List<dynamic>? addons;
  final PaymentSummary? paymentSummary;

  BookingModel({
    required this.id,
    this.bookingNumber,
    required this.service,
    required this.category,
    required this.date,
    required this.time,
    required this.status,
    this.rawStatus,
    this.statusColor,
    required this.price,
    required this.partner,
    required this.image,
    this.partnerPhone,
    this.partnerRating,
    this.partnerAvatar,
    this.partnerLatitude,
    this.partnerLongitude,
    this.paymentMethod,
    this.paymentStatus,
    this.address,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.estimatedArrivalMinutes,
    this.otpStart,
    this.otpEnd,
    this.addons,
    this.paymentSummary,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      bookingNumber: json['booking_number']?.toString() ?? json['bookingNumber']?.toString(),
      service: json['service'] as String? ?? '',
      category: json['category'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      status: json['status'] as String? ?? '',
      rawStatus: json['raw_status'] as String?,
      statusColor: json['statusColor'] as String?,
      price: json['price']?.toString() ?? '',
      partner: json['partner'] as String? ?? 'Not Assigned',
      image: json['image'] as String? ?? '',
      partnerPhone: json['partnerPhone']?.toString() ?? json['partner_phone']?.toString(),
      partnerRating: double.tryParse(json['partnerRating']?.toString() ?? json['partner_rating']?.toString() ?? '0.0'),
      partnerAvatar: json['partnerAvatar'] as String? ?? json['partner_avatar'] as String?,
      partnerLatitude: double.tryParse(json['partnerLatitude']?.toString() ?? json['partner_latitude']?.toString() ?? ''),
      partnerLongitude: double.tryParse(json['partnerLongitude']?.toString() ?? json['partner_longitude']?.toString() ?? ''),
      paymentMethod: json['payment_method'] as String? ?? json['paymentMethod'] as String?,
      paymentStatus: json['payment_status'] as String? ?? json['paymentStatus'] as String?,
      address: json['address'] as String?,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'] as int? ?? json['etaMinutes'] as int? ?? json['estimated_arrival_minutes'] as int?,
      otpStart: json['otp_start']?.toString() ?? json['otpStart']?.toString(),
      otpEnd: json['otp_end']?.toString() ?? json['otpEnd']?.toString(),
      addons: json['addons'] as List<dynamic>?,
      paymentSummary: json['payment_summary'] != null 
          ? PaymentSummary.fromJson(json['payment_summary'] as Map<String, dynamic>)
          : json['paymentSummary'] != null
              ? PaymentSummary.fromJson(json['paymentSummary'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_number': bookingNumber,
      'service': service,
      'category': category,
      'date': date,
      'time': time,
      'status': status,
      'raw_status': rawStatus,
      'statusColor': statusColor,
      'price': price,
      'partner': partner,
      'image': image,
      'partnerPhone': partnerPhone,
      'partnerRating': partnerRating,
      'partnerAvatar': partnerAvatar,
      'partnerLatitude': partnerLatitude,
      'partnerLongitude': partnerLongitude,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'otp_start': otpStart,
      'otp_end': otpEnd,
      'addons': addons,
      'payment_summary': paymentSummary?.toJson(),
    };
  }
}
