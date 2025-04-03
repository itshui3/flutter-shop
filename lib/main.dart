import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_shop/api/product_service.dart';
import 'package:flutter_shop/api/account_service.dart';

import 'package:flutter_shop/providers/auth_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthModel(),
      child: const MainApp(),
    ),
  );
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
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginPage> {
  final horizontalPadding = 30.0;
  final _loginService = LoginService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter Shop')),
      body: Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
        ),
        child: Column(
          children: [
            Image.asset(
              'assets/images/shopping-cart-pink.png',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            Consumer<AuthModel>(
              builder: (context, auth, child) {
                if (auth.isAuthenticated) {
                  return Column(
                    children: [
                      const Text('Already logged in'),
                      FilledButton(
                        child: const Text('Logout'),
                        onPressed: () {
                          auth.clearToken();
                        },
                      ),
                    ],
                  );
                } else {
                  return Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(labelText: 'Username'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(labelText: 'Password'),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/shop');
                            },
                            child: Text('Shop as guest'),
                          ),
                        ),
                        FilledButton(
                          style: ButtonStyle(),
                          child: const Text('Login'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // Perform login action
                              var loginResponse = await _loginService.login(
                                _usernameController.text,
                                _passwordController.text,
                              );

                              if (loginResponse.isLoggedInSuccessfully) {
                                // Navigate to shop page
                                auth.setToken(loginResponse.authToken);
                                Navigator.pushNamed(context, '/shop');
                              } else {
                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      loginResponse.errorMessage ??
                                          'Login failed',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      // bottomSheet: Expanded(
      //   child: FilledButton(
      //     child: const Text('Start Shopping'),
      //     onPressed: () {
      //       Navigator.pushNamed(context, '/shop');
      //     },
      //   ),
      // ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            leading: Image.network(product.thumbnail, fit: BoxFit.cover),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(product.title)),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            subtitle: Text(product.description),
            onTap: () {
              Navigator.pushNamed(context, '/shop/${product.id}');
            },
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
                children: [
                  Row(
                    children: [
                      Flexible(
                        flex: 1,
                        child: Image.network(
                          _product!.images[0],
                          fit: BoxFit.cover,
                        ),
                      ),
                      Flexible(
                        // Wrap details column in Flexible
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _product!.rating.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.black54),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _product!.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _product!.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${_product!.price.toStringAsFixed(2)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('add to cart filler'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Reviews
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        'Reviews',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    itemCount: _product!.reviews.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final review = _product!.reviews[index];
                      return ListTile(
                        title: Text(review.comment),
                        subtitle: Text(
                          '${review.rating} stars by ${review.reviewerName}',
                        ),
                        trailing: Text(
                          review.date.toLocal().toString().split(' ')[0],
                        ),
                      );
                    },
                  ),
                ],
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
