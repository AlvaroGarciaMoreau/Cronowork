class Category {
  final String id;
  final String name;
  final String userId;

  Category({required this.id, required this.name, required this.userId});

  Map<String, dynamic> toMap() {
    return {'name': name, 'userId': userId};
  }

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] as String,
      userId: map['userId'] as String,
    );
  }
}
