import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductService {
  fetchProducts(int page, int limit) async {
    var productsUri = Uri.https('dummyjson.com', 'products', {
      'limit': limit.toString(),
      'skip': (page * limit).toString(),
    });
    var response = await http.get(productsUri);
    if (response.statusCode == 200) {
      var data = json.decode(response.body) as Map<String, dynamic>;
      Products products = Products.fromJson(data);
      return products;
    } else {
      throw Exception('Failed to load products');
    }
  }

  fetchProduct(int productId) async {
    var productUri = Uri.https('dummyjson.com', 'products/$productId');
    var response = await http.get(productUri);

    if (response.statusCode == 200) {
      var data = json.decode(response.body) as Map<String, dynamic>;

      Product product = Product(
        id: data['id'] as int,
        title: data['title'] as String,
        description: data['description'] as String,
      );
      return product;
    } else {
      throw Exception('Failed to load products');
    }
  }
}

class Product {
  final int id;
  final String title;
  final String description;

  Product({required this.id, required this.title, required this.description});
}

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
}
