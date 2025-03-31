Serializing JSON within model class

ie.

class Products {
final List<Product> products;

Products({required this.products});

Products.fromJson(Map<String, dynamic> json)
: products =
(json['products'] as List<dynamic>)
.map(
(productJson) => Product(
id: productJson['id'] as int,
title: productJson['title'] as String,
description: productJson['description'] as String,
),
)
.toList();

Map<String, dynamic> toJson() => {'products': List<Product>};
}
