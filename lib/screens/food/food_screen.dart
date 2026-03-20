import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../models/food_model.dart';
import '../../core/providers/auth_provider.dart';
import '../profile/profile_screen.dart';
import '../../core/providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../../widgets/main_drawer.dart';
import '../auth/login.dart';
import '../home/home.dart';





class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  _FoodScreenState createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  List<Food> foods = [];
  bool isLoading = true;
  String? errorMessage;
  final api = ApiService();

  void _addToCart(Food food) {
    Provider.of<CartProvider>(context, listen: false).addItem(food);

    // Show a quick snackbar notification
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${food.name} added to cart!"),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: "View",
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    fetchFoods();
  }

  fetchFoods() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await api.get("food");
      // The backend returns an object: { "list": [...], "message": "..." }
      if (response != null && response['list'] != null) {
        final List<dynamic> listData = response['list'];
        setState(() {
          foods = listData.map((json) => Food.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "No list found in response";
        });
      }
    } catch (e) {
      debugPrint("Error fetching foods: $e");
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        centerTitle: true,

        backgroundColor: Colors.orange[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(

          "Delicious Food Store",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.isAuthenticated) {
                return IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
                  icon: const Icon(Icons.login, color: Colors.white),
                );
              }
              final user = auth.user;
              return PopupMenuButton<String>(

                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  } else if (value == 'logout') {
                    auth.logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  }
                },
                offset: const Offset(0, 50),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.orange),
                        SizedBox(width: 10),
                        Text("Profile"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Logout"),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 18,
                    backgroundImage: user?['image'] != null && user!['image'].isNotEmpty
                        ? NetworkImage(user['image'])
                        : null,
                    child: user?['image'] == null || user!['image'].isEmpty
                        ? const Icon(Icons.person, color: Colors.orange, size: 18)
                        : null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => fetchFoods(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchFoods,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (foods.isEmpty) {
      return const Center(child: Text("No food items available."));
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildWelcomeCard()),
        SliverToBoxAdapter(child: _buildCategories()),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              "Popular Dishes",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final food = foods[index];
                return _buildFoodCard(food);
              },
              childCount: foods.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[800]!, Colors.orange[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome to Foodify!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Explore the best dishes from your favorite local restaurants. Fresh, fast, and delivered to you.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ["All", "🍔 Burgers", "🍕 Pizza", "🍣 Sushi", "🍰 Desserts"];
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isActive = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.orange[700] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? Colors.orange[700]! : Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildFoodCard(Food food) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                food.image,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "\$${food.price.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _addToCart(food),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text(
                      "Add to Cart",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
