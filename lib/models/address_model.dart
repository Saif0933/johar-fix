class AddressModel {
  final String id;
  final String type; // Home, Work, Other
  final String? label;
  final String? houseNo;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final double lat;
  final double lng;
  final String? contactName;
  final String? contactNumber;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.type,
    this.label,
    this.houseNo,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.lat,
    required this.lng,
    this.contactName,
    this.contactNumber,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    // Map fields from both snake_case (API) and camelCase (local Cache)
    final idVal = json['id']?.toString() ?? '';
    final typeVal = json['type'] as String? ?? 'Other';
    final isDefaultVal = json['is_default'] == true || 
        json['is_default'] == 1 || 
        json['is_default'] == '1' || 
        json['isDefault'] == true;

    return AddressModel(
      id: idVal,
      type: typeVal,
      label: json['label'] as String?,
      houseNo: json['house_no'] as String? ?? json['houseNo'] as String?,
      landmark: json['landmark'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0.0') ?? 0.0,
      lng: double.tryParse(json['lng']?.toString() ?? '0.0') ?? 0.0,
      contactName: json['contact_name'] as String? ?? json['contactName'] as String?,
      contactNumber: json['contact_number'] as String? ?? json['contactNumber'] as String?,
      isDefault: isDefaultVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'label': label,
      'house_no': houseNo,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
      'lat': lat,
      'lng': lng,
      'contact_name': contactName,
      'contact_number': contactNumber,
      'is_default': isDefault,
    };
  }

  AddressModel copyWith({
    String? id,
    String? type,
    String? label,
    String? houseNo,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    double? lat,
    double? lng,
    String? contactName,
    String? contactNumber,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      houseNo: houseNo ?? this.houseNo,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      contactName: contactName ?? this.contactName,
      contactNumber: contactNumber ?? this.contactNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
