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
      initialRoute: '/login',
      routes: {
        '/': (context) => const LoadingPage(),
        '/login': (context) => const LoginPage(),
        '/shop': (context) => const ShopPage(),
      },
      onGenerateRoute: (settings) {
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
      appBar: AppBar(
        title: Row(
          children: [
            Text('Flutter Shop'),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Flow Info'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'on sign in: store auth token, redirect to shop',
                          ),
                          Text(
                            'on click shop as guest: redirect to shop without auth',
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Image.asset(
                'assets/images/info.png',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
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
                              var loginResponse = await _loginService.login(
                                _usernameController.text,
                                _passwordController.text,
                              );

                              if (loginResponse.isLoggedInSuccessfully) {
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
  final _searchController = TextEditingController();
  Products _products = Products(products: []);

  String? selectedCategory;
  int page = 0;
  int limit = 20;
  final List<int> limitOptions = [10, 20, 50];
  String query = '';

  @override
  void initState() {
    super.initState();
    getProducts(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Shop'),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Flow Info'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'on page load: fetch categories list, use it to fetch products by category',
                          ),
                          Text(
                            'on category change: fetch products by category',
                          ),
                          Text('on search: fetch products by query'),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Image.asset(
                'assets/images/info.png',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FutureBuilder<List<String>>(
                      future: _productsService.fetchCategoriesList(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Text('Error loading categories');
                        }

                        final categoriesList = snapshot.data ?? [];
                        return DropdownButton<String>(
                          value: selectedCategory ?? categoriesList[0],
                          hint: const Text('Category'),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          underline: const SizedBox(),
                          items:
                              categoriesList.map((String category) {
                                var categoryLabel = category
                                    .split('-')
                                    .map(
                                      (category) =>
                                          category[0].toUpperCase() +
                                          category.substring(1),
                                    )
                                    .join(' ');
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(categoryLabel),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedCategory = newValue;
                              });
                              getProductsByCategory();
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        query = value;
                      },
                    ),
                  ),

                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      getProducts(query);
                    },
                    child: const Text('Search'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _products.products.length,
                itemBuilder: (context, index) {
                  final product = _products.products[index];
                  return ListTile(
                    leading: Image.network(
                      product.thumbnail,
                      fit: BoxFit.cover,
                    ),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Page controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      page > 0
                          ? () {
                            setState(() {
                              page--;
                            });
                            getProducts(query);
                          }
                          : null,
                ),
                Text('Page ${page + 1}'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _products.products.length >= limit
                          ? () {
                            setState(() {
                              page++;
                            });
                            getProducts(query);
                          }
                          : null,
                ),
              ],
            ),
            // Limit dropdown
            Row(
              children: [
                const Text('Items per page: '),
                DropdownButton<int>(
                  value: limit,
                  items:
                      limitOptions.map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      limit = newValue as int;
                      page = 0;
                    });
                    getProducts(query);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void getProducts(String query) async {
    var products = await _productsService.fetchProducts(page, limit, query);

    setState(() {
      _products = products;
    });
  }

  void getProductsByCategory() async {
    if (selectedCategory != null) {
      var products = await _productsService.fetchProductsByCategory(
        selectedCategory as String,
      );

      setState(() {
        _products = products;
      });
    }
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
              : SingleChildScrollView(
                child: Column(
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
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
