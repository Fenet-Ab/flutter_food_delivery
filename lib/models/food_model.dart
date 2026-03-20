class Food {
  final String id;
  final String name;
  final String image;
  final double price;

  Food({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      image: json['image'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }
}
