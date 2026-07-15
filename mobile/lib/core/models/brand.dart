class Brand {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final bool isActive;

  Brand({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.isActive,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}
