import 'package:flutter/material.dart';
import 'package:flutter_shop/api/index.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Set initial route to login page
      initialRoute: '/login',

      // Define named routes
      routes: {
        '/': (context) => const LoadingPage(),
        '/login': (context) => const LoginPage(),
        '/shop': (context) => const ShopPage(),
      },
      onGenerateRoute: (settings) {
        // pdp routes
        if (settings.name?.startsWith('/shop/') ?? false) {
          final productId = int.parse(settings.name!.split('/').last);
          return MaterialPageRoute(
            builder: (context) => ProductPage(productId: productId),
          );
        }

        return null;
      },
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Text('Loading');
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Text('hi'),
      bottomSheet: OutlinedButton(
        child: const Text('Start Shopping'),
        onPressed: () {
          Navigator.pushNamed(context, '/shop');
        },
      ),
    );
  }
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  ShopPageState createState() => ShopPageState();
}

class ShopPageState extends State<ShopPage> {
  final _productsService = ProductService();
  Products _products = Products(products: []);

  int page = 0;
  int limit = 20;

  @override
  void initState() {
    super.initState();
    getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: ListView.builder(
        itemCount: _products.products.length,
        itemBuilder: (context, index) {
          final product = _products.products[index];
          return ListTile(
            title: Text(product.title),
            subtitle: Text(product.description),
            trailing: OutlinedButton(
              child: Text('Product Page'),
              onPressed: () {
                Navigator.pushNamed(context, '/shop/${product.id}');
              },
            ),
          );
        },
      ),
    );
  }

  void getProducts() async {
    var products = await _productsService.fetchProducts(page, limit);

    setState(() {
      _products = products;
    });
  }
}

class ProductPage extends StatefulWidget {
  final int productId;

  const ProductPage({super.key, required this.productId});

  @override
  ProductPageState createState() => ProductPageState();
}

class ProductPageState extends State<ProductPage> {
  final _productsService = ProductService();
  Product? _product;

  @override
  void initState() {
    super.initState();
    getProduct();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Page')),
      body:
          _product == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [Text(_product!.title), Text(_product!.description)],
              ),
    );
  }

  void getProduct() async {
    var product = await _productsService.fetchProduct(widget.productId);

    setState(() {
      _product = product;
    });
  }
}
