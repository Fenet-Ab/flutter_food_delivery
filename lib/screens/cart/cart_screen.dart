import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text("Your cart is empty!", style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(item.image),
                              radius: 25,
                            ),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("\$${(item.price * item.quantity).toStringAsFixed(2)}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                  onPressed: () => cart.removeSingleItem(item.id),
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                                  onPressed: () => cart.incrementQuantity(item.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text("\$${cart.totalAmount.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement Checkout logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("CHECKOUT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
