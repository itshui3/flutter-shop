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
        price: data['price'] as double,
        images:
            (data['images'] as List<dynamic>)
                .map((image) => image as String)
                .toList(),
        thumbnail: data['thumbnail'] as String,
        rating: data['rating'] as double,
        reviews:
            data['reviews'] != null
                ? (data['reviews'] as List<dynamic>)
                    .map((reviewJson) => Review.fromJson(reviewJson))
                    .toList()
                : [],
      );
      return product;
    } else {
      throw Exception('Failed to load products');
    }
  }
}

class Review {
  final int rating;
  final String comment;
  final DateTime date;
  final String reviewerName;
  final String reviewerEmail;

  Review({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
    required this.reviewerEmail,
  });

  Review.fromJson(Map<String, dynamic> json)
    : rating = json['rating'] as int,
      comment = json['comment'] as String,
      date = DateTime.parse(json['date'] as String),
      reviewerName = json['reviewerName'] as String,
      reviewerEmail = json['reviewerEmail'] as String;
}

class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final List<String> images;
  final String thumbnail;
  final double rating;
  final List<Review> reviews;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.thumbnail,
    required this.rating,
    required this.reviews,
  });
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
                  price: productJson['price'] as double,
                  images:
                      (productJson['images'] as List<dynamic>)
                          .map((image) => image as String)
                          .toList(),
                  thumbnail: productJson['thumbnail'] as String,
                  rating: productJson['rating'] as double,
                  reviews:
                      productJson['reviews'] != null
                          ? (productJson['reviews'] as List<dynamic>)
                              .map((reviewJson) => Review.fromJson(reviewJson))
                              .toList()
                          : [],
                ),
              )
              .toList();
}
