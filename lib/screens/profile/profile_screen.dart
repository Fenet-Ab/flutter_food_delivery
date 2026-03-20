import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../home/home.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  final _picker = ImagePicker();
  
  XFile? _pickedFile;
  Uint8List? _imageBytes;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController.text = user?['name'] ?? "";
    _emailController.text = user?['email'] ?? "";
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(context, listen: false).updateProfile(
      _nameController.text.trim(),
      _emailController.text.trim(),
      imagePath: kIsWeb ? null : _pickedFile?.path,
      imageBytes: _imageBytes,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update failed"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.orange[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: _imageBytes != null
                                ? MemoryImage(_imageBytes!)
                                : (user?['image'] != null && user!['image'].isNotEmpty)
                                    ? NetworkImage(user['image']) as ImageProvider
                                    : null,
                            child: (_imageBytes == null && (user?['image'] == null || user!['image'].isEmpty))
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: _pickImage,
                              icon: const CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 20,
                                child: Icon(Icons.camera_alt, color: Colors.orange),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_isEditing)
                      Text(
                        user?['name'] ?? "User Name",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter Name",
                            hintStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    if (!_isEditing)
                      Text(
                        user?['email'] ?? "Email",
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (!_isEditing) ...[
                        _buildListTile(Icons.person, "Full Name", user?['name'] ?? "N/A"),
                        const Divider(height: 1),
                        _buildListTile(Icons.email, "Email", user?['email'] ?? "N/A"),
                      ] else ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
                        ),
                      ],
                      const Divider(height: 1),
                      _buildListTile(Icons.security, "Role", user?['role']?.toString().toUpperCase() ?? "USER"),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      authProvider.logout();
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Log Out"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange[700]),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      visualDensity: VisualDensity.compact,
    );
  }
}
