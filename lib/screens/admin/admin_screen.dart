import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import '../../widgets/main_drawer.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  List<dynamic> _foods = [];
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      debugPrint("Admin: Fetching all system data...");
      
      final ordersRes = await _api.get('order/all', token: token);
      final foodsRes = await _api.get('food');
      final usersRes = await _api.get('user/get-all-users', token: token);
      
      debugPrint("Status Check:");
      if (ordersRes is Map && ordersRes.containsKey('statusCode')) debugPrint("Orders Request Failed: ${ordersRes['message']}");
      if (usersRes is Map && usersRes.containsKey('statusCode')) {
         debugPrint("Users Request Failed: ${usersRes['message']}");
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Fetch Failed: ${usersRes['message']}")));
      }

      setState(() {
        // Parse Orders
        if (ordersRes is List) {
          _orders = ordersRes;
        } else if (ordersRes != null && ordersRes['list'] != null) {
          _orders = ordersRes['list'];
        }
        
        // Parse Foods
        if (foodsRes != null && foodsRes['list'] != null) {
          _foods = foodsRes['list'];
        } else if (foodsRes is List) {
          _foods = foodsRes;
        }
        
        // Parse Users
        if (usersRes is List) {
          _users = usersRes;
        } else if (usersRes != null && usersRes['list'] != null) {
          _users = usersRes['list'];
        }
      });
      
      debugPrint("Data Loaded: ${_orders.length} orders, ${_foods.length} foods, ${_users.length} users.");
      
    } catch (e) {
      debugPrint("Admin Data Fetch Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String id, String newStatus) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      await _api.patch('order/$id/status', {'status': newStatus}, token: token);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order status: $newStatus")));
      _fetchData();
    } catch (e) {
      debugPrint("Update status error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const MainDrawer(),
        appBar: AppBar(
          title: const Text("Admin Hub", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.indigo[900],
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: "Orders"),
              Tab(icon: Icon(Icons.restaurant_menu), text: "Foods"),
              Tab(icon: Icon(Icons.group), text: "Users"),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh, color: Colors.white),
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildOrderList(),
                  _buildFoodList(),
                  _buildUserList(),
                ],
              ),
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddFoodDialog(context),
            label: const Text("Create Food"),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.orange[700],
          );
        }),
      ),
    );
  }

  Widget _buildOrderList() {
    if (_orders.isEmpty) return const Center(child: Text("No orders found."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return Card(
          elevation: 5,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Order #${order['id'].toString().substring(0, 8)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    _buildStatusChip(order['status'] ?? 'pending'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: order['user']?['image'] != null && order['user']!['image'].isNotEmpty
                          ? NetworkImage(order['user']!['image'])
                          : null,
                      child: order['user']?['image'] == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['user']?['name'] ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(order['user']?['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 30),
                ...((order['items'] as List).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${item['name']} x${item['quantity']}"),
                          Text("\$${(item['price'] * item['quantity']).toStringAsFixed(2)}"),
                        ],
                      ),
                    ))),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Amount:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("\$${order['total']}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Set Status:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["pending", "out for delivery", "delivered"].map((status) {
                      bool isCurrent = order['status'] == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: isCurrent ? Colors.white : Colors.black87)),
                          selected: isCurrent,
                          selectedColor: Colors.orange[700],
                          onSelected: (selected) {
                            if (selected) _updateOrderStatus(order['id'], status);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoodList() {
    if (_foods.isEmpty) return const Center(child: Text("No food items."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _foods.length,
      itemBuilder: (context, index) {
        final food = _foods[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (food['image'] != null && food['image'].isNotEmpty)
                  ? Image.network(food['image'], width: 60, height: 60, fit: BoxFit.cover, 
                      errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 40))
                  : const Icon(Icons.fastfood, size: 40),
            ),
            title: Text(food['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(food['category'] ?? 'others', style: TextStyle(color: Colors.orange[800])),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("\$${food['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserList() {
    if (_users.isEmpty) return const Center(child: Text("No users found. Tap refresh to try again."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user['image'] != null && user['image'].isNotEmpty ? NetworkImage(user['image']) : null,
              child: user['image'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(user['name'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user['email'] ?? ""),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(8)),
              child: Text(user['role']?.toUpperCase() ?? "USER", style: const TextStyle(color: Colors.indigo, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    if (status == 'pending') color = Colors.orange;
    if (status == 'out for delivery') color = Colors.blue;
    if (status == 'delivered') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(), 
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  final _picker = ImagePicker();
  XFile? _dialogImageFile;
  Uint8List? _dialogImageBytes;

  void _showAddFoodDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    String? categoryValue = "Burgers";
    bool subLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text("Add New Food Item", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await _picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setDialogState(() {
                        _dialogImageFile = picked;
                        _dialogImageBytes = bytes;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                      image: _dialogImageBytes != null ? DecorationImage(image: MemoryImage(_dialogImageBytes!), fit: BoxFit.cover) : null,
                    ),
                    child: _dialogImageBytes == null ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 50, color: Colors.grey),
                        Text("Tap to pick image", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ) : null,
                  ),
                ),
                const SizedBox(height: 20),
                _buildField(nameController, "Food Name", Icons.fastfood),
                _buildField(descController, "Description", Icons.description),
                _buildField(priceController, "Price", Icons.attach_money, isNumeric: true),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: categoryValue,
                  items: ["Burgers", "Pizza", "Sushi", "Desserts", "Drinks"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => categoryValue = val,
                  decoration: InputDecoration(
                    labelText: "Category",
                    prefixIcon: const Icon(Icons.category),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actions: [
            TextButton(onPressed: () {
              setDialogState(() {
                _dialogImageFile = null;
                _dialogImageBytes = null;
              });
              Navigator.pop(ctx);
            }, child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: subLoading ? null : () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Price are required")));
                   return;
                }
                setDialogState(() => subLoading = true);
                final token = Provider.of<AuthProvider>(ctx, listen: false).token;
                
                final response = await _api.postMultipart('food', {
                  'name': nameController.text,
                  'description': descController.text,
                  'price': priceController.text,
                  'category': categoryValue!,
                }, token: token, 
                   filePath: kIsWeb ? null : _dialogImageFile?.path, 
                   bytes: _dialogImageBytes,
                   fieldName: 'image');

                if (response != null && response['message'] != null) {
                  Navigator.pop(ctx);
                  setDialogState(() {
                    _dialogImageFile = null;
                    _dialogImageBytes = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Food created!")));
                  _fetchData();
                } else {
                  setDialogState(() => subLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create food")));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: subLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("ADD FOOD", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
