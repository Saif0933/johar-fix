class CategoryModel {
  final int id;
  final String name;
  final String? slug;
  final String? image;
  final String? icon;
  final String? color;
  final bool status;

  CategoryModel({
    required this.id,
    required this.name,
    this.slug,
    this.image,
    this.icon,
    this.color,
    required this.status,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      image: json['image'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      status: json['status'] == true || json['status'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image': image,
      'icon': icon,
      'color': color,
      'status': status,
    };
  }
}
