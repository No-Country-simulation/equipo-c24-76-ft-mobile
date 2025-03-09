import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  String username = "Cargando...";
  String bio = "Cargando...";
  String avatarUrl = "https://via.placeholder.com/150"; // Valor por defecto
  bool isLoading = true;
  bool showSettings = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, "/login");
        return;
      }

      // Selecciona 'username, bio, avatar_url' de la tabla 'users'
      final data = await supabase
          .from('users')
          .select('username, bio, avatar_url')
          .eq('id', user.id)
          .single();

      setState(() {
        username = data['username'] ?? "Sin nombre";
        bio = data['bio'] ?? "Sin biografía";
        avatarUrl = data['avatar_url'] ?? "https://via.placeholder.com/150";
        isLoading = false;
      });
    } catch (error) {
      print("Error cargando el perfil: $error");
      setState(() {
        username = "Error";
        bio = "No se pudo cargar la biografía";
        isLoading = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final usernameController = TextEditingController(text: username);
    final bioController = TextEditingController(text: bio);
    final avatarController = TextEditingController(text: avatarUrl);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Perfil"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Nombre de usuario"),
              ),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: "Biografía"),
              ),
              TextField(
                controller: avatarController,
                decoration: const InputDecoration(labelText: "URL del avatar"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = supabase.auth.currentUser;
                if (user == null) return;

                try {
                  await supabase.from('users').update({
                    'username': usernameController.text.trim(),
                    'bio': bioController.text.trim(),
                    'avatar_url': avatarController.text.trim(),
                  }).eq('id', user.id);

                  setState(() {
                    username = usernameController.text.trim();
                    bio = bioController.text.trim();
                    avatarUrl = avatarController.text.trim();
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Error al actualizar: $e"),
                    backgroundColor: Colors.red,
                  ));
                }
                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                showSettings = !showSettings;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : showSettings
              ? _buildSettingsScreen()
              : _buildProfileScreen(),
    );
  }

  Widget _buildProfileScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _editProfile,
                  child: const Text("Editar perfil"),
                ),
              ],
            ),
          ),
          const Divider(),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return Image.network(
                'https://via.placeholder.com/150',
                fit: BoxFit.cover,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text("Editar Perfil"),
          onTap: _editProfile,
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text("Cerrar sesión"),
          onTap: _logout,
        ),
      ],
    );
  }
}
