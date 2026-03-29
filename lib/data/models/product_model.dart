class ProductModel {
  final String id;
  final String title;

  ProductModel({required this.id, required this.title});

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
      );
}
