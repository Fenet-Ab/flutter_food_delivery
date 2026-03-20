import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../screens/auth/login.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/home/home.dart';
import '../screens/admin/admin_screen.dart';



class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.orange[700]),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?['image'] != null && user!['image'].isNotEmpty
                  ? NetworkImage(user['image'])
                  : null,
              child: user?['image'] == null || user!['image'].isEmpty
                  ? const Icon(Icons.person, color: Colors.orange, size: 40)
                  : null,
            ),
            accountName: Text(user?['name'] ?? "Guest User", style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(user?['email'] ?? "Log in to see more"),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text("My Cart"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const CartScreen()));
            },
          ),
          if (auth.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("My Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ProfileScreen()));
              },
            ),
          if (auth.isAuthenticated && user?['role'] == 'admin')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
              title: const Text("Admin Dashboard"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AdminScreen()));
              },
            ),

          const Spacer(),
          const Divider(),
          if (auth.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () {
                auth.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login, color: Colors.green),
              title: const Text("Login / Register"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AuthScreen()));
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
